require "test_helper"
require 'sidekiq/api'

class Admin::RateCacheControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token = "secret-token"
    @auth_headers = { 'HTTP_AUTHORIZATION' => "Token token=#{@token}" }
  end

  test "POST /admin/rate_cache/refresh should return 401 without token" do
    post "/admin/rate_cache/refresh"
    assert_response :unauthorized
  end

  test "POST /admin/rate_cache/refresh should call RateCacheService#set_rate and reset Sidekiq with valid token" do
    mock_service = Minitest::Mock.new
    mock_service.expect :set_rate, true

    mock_queue = Minitest::Mock.new
    mock_queue.expect :clear, nil
    
    mock_scheduled = Minitest::Mock.new
    mock_scheduled.expect :clear, nil
    
    mock_retry = Minitest::Mock.new
    mock_retry.expect :clear, nil

    RateCacheService.stub :new, mock_service do
      Sidekiq::Queue.stub :new, mock_queue do
        Sidekiq::ScheduledSet.stub :new, mock_scheduled do
          Sidekiq::RetrySet.stub :new, mock_retry do
            post "/admin/rate_cache/refresh", headers: @auth_headers
          end
        end
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_match /Rate cache refreshed and Sidekiq queues cleared/, json_response["message"]
    mock_service.verify
    mock_queue.verify
    mock_scheduled.verify
    mock_retry.verify
  end
end
