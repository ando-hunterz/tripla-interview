require "test_helper"

class Api::V1::PricingControllerTest < ActionDispatch::IntegrationTest
  def setup
    @url = "/api/v1/pricing"
    @valid_params = { period: "Summer", hotel: "FloatingPointResort", room: "BooleanTwin" }
  end

  test "index should return 200 with rate if valid" do
    mock_service = Minitest::Mock.new
    mock_service.expect :run, nil
    mock_service.expect :valid?, true
    mock_service.expect :result, 100

    Api::V1::PricingService.stub :new, mock_service do
      get @url, params: @valid_params
      assert_response :success
      assert_equal 100, JSON.parse(response.body)["rate"]
    end
  end

  test "index should return 404 if rate not found" do
    mock_service = Minitest::Mock.new
    mock_service.expect :run, nil
    mock_service.expect :valid?, false
    mock_service.expect :errors, ["RATE_NOT_FOUND"]

    Api::V1::PricingService.stub :new, mock_service do
      get @url, params: @valid_params
      assert_response :not_found
      assert_equal "RATE_NOT_FOUND", JSON.parse(response.body)["error"]["code"]
    end
  end

  test "index should return 400 for missing parameters" do
    get @url, params: { period: "Summer" }
    assert_response :bad_request
    assert_equal "MISSING_PARAMETERS", JSON.parse(response.body)["error"]["code"]
  end

  test "index should return 400 for invalid period" do
    get @url, params: @valid_params.merge(period: "Invalid")
    assert_response :bad_request
    assert_equal "INVALID_PERIOD", JSON.parse(response.body)["error"]["code"]
  end
end
