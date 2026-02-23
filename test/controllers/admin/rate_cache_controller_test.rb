require "test_helper"
require "sidekiq/api"

class Admin::RateCacheControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin_token = ENV.fetch("ADMIN_TOKEN", "ce2c7c1df165336a21e04cd917875f0f")
  end

  test "should return 401 Unauthorized when token is missing" do
    post admin_rate_cache_refresh_url
    assert_response :unauthorized
  end

  test "should return 401 Unauthorized when token is incorrect" do
    post admin_rate_cache_refresh_url, headers: { "Authorization" => "Token wrong_token" }
    assert_response :unauthorized
  end

  test "should return 200 OK and clear Sidekiq queues when token is correct" do
    # Mock Sidekiq queues
    queue_mock = Minitest::Mock.new
    queue_mock.expect :clear, nil
    
    scheduled_set_mock = Minitest::Mock.new
    scheduled_set_mock.expect :clear, nil
    
    retry_set_mock = Minitest::Mock.new
    retry_set_mock.expect :clear, nil

    # Mock RateCacheService
    service_mock = Minitest::Mock.new
    service_mock.expect :set_rate, nil

    Sidekiq::Queue.stub :new, queue_mock do
      Sidekiq::ScheduledSet.stub :new, scheduled_set_mock do
        Sidekiq::RetrySet.stub :new, retry_set_mock do
          RateCacheService.stub :new, service_mock do
            post admin_rate_cache_refresh_url, headers: { "Authorization" => "Token #{@admin_token}" }
            
            assert_response :success
            json_response = JSON.parse(response.body)
            assert_equal "Rate cache refreshed and Sidekiq queues cleared", json_response["message"]
          end
        end
      end
    end

    queue_mock.verify
    scheduled_set_mock.verify
    retry_set_mock.verify
    service_mock.verify
  end

  test "should return 500 Internal Server Error when an exception occurs" do
    # Mocking an exception during clear
    Sidekiq::Queue.stub :new, -> { raise StandardError.new("Sidekiq error") } do
      post admin_rate_cache_refresh_url, headers: { "Authorization" => "Token #{@admin_token}" }
      
      assert_response :internal_server_error
      json_response = JSON.parse(response.body)
      assert_match /Failed to refresh cache or reset Sidekiq/, json_response["error"]
      assert_match /Sidekiq error/, json_response["error"]
    end
  end

  test "should retry up to 3 times before failing if set_rate raises an error" do
    call_count = 0
    RateCacheService.stub :new, -> do
      mock = Object.new
      mock.define_singleton_method(:set_rate) do
        call_count += 1
        raise StandardError.new("API Error")
      end
      mock
    end do
      Kernel.stub(:sleep, nil) do
        post admin_rate_cache_refresh_url, headers: { "Authorization" => "Token #{@admin_token}" }
      end
    end

    assert_response :internal_server_error
    assert_equal 3, call_count
    
    json_response = JSON.parse(response.body)
    assert_match /API Error/, json_response["error"]
  end
end
