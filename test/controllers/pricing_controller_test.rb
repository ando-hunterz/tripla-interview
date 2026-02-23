require "test_helper"

class Api::V1::PricingControllerTest < ActionDispatch::IntegrationTest
  test "should get pricing with all parameters" do
    mock_cache = Minitest::Mock.new
    mock_cache.expect :get_rate, "15000", ["Summer", "FloatingPointResort", "SingletonRoom"]

    RateCacheService.stub(:new, mock_cache) do
      get api_v1_pricing_url, params: {
        period: "Summer",
        hotel: "FloatingPointResort",
        room: "SingletonRoom"
      }

      assert_response :success
      assert_equal "application/json", @response.media_type

      json_response = JSON.parse(@response.body)
      assert_equal "15000", json_response["rate"]
    end

    mock_cache.verify
  end

  test "should return error when rate API fails" do
    mock_cache = Minitest::Mock.new
    mock_cache.expect :get_rate, nil, ["Summer", "FloatingPointResort", "SingletonRoom"]

    RateCacheService.stub(:new, mock_cache) do
      get api_v1_pricing_url, params: {
        period: "Summer",
        hotel: "FloatingPointResort",
        room: "SingletonRoom"
      }

      assert_response :not_found
      assert_equal "application/json", @response.media_type

      json_response = JSON.parse(@response.body)
      assert_equal "RATE_NOT_FOUND", json_response["error"]["code"]
    end

    mock_cache.verify
  end

  test "should return error when PricingService Error" do
    RateCacheService.stub :new, -> { raise StandardError.new("Redis connection error") } do
      get api_v1_pricing_url, params: {
        period: "Summer",
        hotel: "FloatingPointResort",
        room: "SingletonRoom"
      }

      assert_response :bad_request
      assert_equal "application/json", @response.media_type

      json_response = JSON.parse(@response.body)
      assert_equal "INTERNAL_ERROR", json_response["error"]["code"]
      assert_match /Redis connection error/, json_response["error"]["message"]
    end
  end

  test "should return error when controller error" do
    Api::V1::PricingService.stub :new, ->(params) { raise StandardError.new("Controller crash") } do
      get api_v1_pricing_url, params: {
        period: "Summer",
        hotel: "FloatingPointResort",
        room: "SingletonRoom"
      }

      assert_response :internal_server_error
      assert_equal "application/json", @response.media_type

      json_response = JSON.parse(@response.body)
      assert_equal "INTERNAL_ERROR", json_response["error"]["code"]
      assert_equal "Controller crash", json_response["error"]["message"]
    end
  end


  test "should return error without any parameters" do
    get api_v1_pricing_url

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"]["message"], "Missing required parameters"
  end

  test "should handle empty parameters" do
    get api_v1_pricing_url, params: {
      period: "",
      hotel: "",
      room: ""
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"]["message"], "Missing required parameters"
  end

  test "should reject invalid period" do
    get api_v1_pricing_url, params: {
      period: "summer-2024",
      hotel: "FloatingPointResort",
      room: "SingletonRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"]["message"], "Invalid period"
  end

  test "should reject invalid hotel" do
    get api_v1_pricing_url, params: {
      period: "Summer",
      hotel: "InvalidHotel",
      room: "SingletonRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"]["message"], "Invalid hotel"
  end

  test "should reject invalid room" do
    get api_v1_pricing_url, params: {
      period: "Summer",
      hotel: "FloatingPointResort",
      room: "InvalidRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"]["message"], "Invalid room"
  end
end
