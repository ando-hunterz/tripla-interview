require "test_helper"

class RateCacheServiceTest < ActiveSupport::TestCase
  def setup
    @service = RateCacheService.new
    # Use a simple mock object for Redis to avoid Minitest::Mock keyword argument issues
    @redis_mock = Minitest::Mock.new
    @service.instance_variable_set(:@redis, @redis_mock)
  end

  test "set_rate should fetch rates and store in redis" do
    mock_response = Minitest::Mock.new
    mock_response.expect :success?, true
    mock_response.expect :parsed_response, {
      "rates" => [
        { "period" => "Summer", "hotel" => "FloatingPointResort", "room" => "BooleanTwin", "rate" => 100 }
      ]
    }

    RateApiClient.stub :get_all_rate, mock_response do
      @redis_mock.expect :set, "OK" do |key, value, options|
        key == "rate.Summer.FloatingPointResort.BooleanTwin" &&
          value == 100 &&
          options == { ex: RateCacheService::CACHE_EXPIRY }
      end
      
      @service.set_rate
      
      @redis_mock.verify
    end
  end

  test "get_rate should fetch rate from redis" do
    @redis_mock.expect :get, "150", ["rate.Summer.FloatingPointResort.BooleanTwin"]
    
    rate = @service.get_rate("Summer", "FloatingPointResort", "BooleanTwin")
    
    assert_equal "150", rate
    @redis_mock.verify
  end

  test "get_rate should returning nil if rate not found" do
    @redis_mock.expect :get, nil, ["rate.Summer.FloatingPointResort.BooleanTwin"]
    
    rate = @service.get_rate("Summer", "FloatingPointResort", "BooleanTwin")
    
    assert_nil rate
    @redis_mock.verify
  end

end
