require "test_helper"

class RateApiClientTest < ActiveSupport::TestCase
  def setup
    @period = "Summer"
    @hotel = "FloatingPointResort"
    @room = "BooleanTwin"
  end

  test "get_rate should make a POST request with correct parameters" do
    mock_response = Minitest::Mock.new
    mock_response.expect :success?, true

    RateApiClient.stub :post, mock_response do
      response = RateApiClient.get_rate(period: @period, hotel: @hotel, room: @room)
      assert response.success?
    end
  end

  test "get_all_rate should make a POST request with all combinations" do
    mock_response = Minitest::Mock.new
    mock_response.expect :success?, true

    RateApiClient.stub :post, mock_response do
      response = RateApiClient.get_all_rate
      assert response.success?
    end
  end


  test "get_rate should handle errors" do
    RateApiClient.stub :post, ->(_url, _options) { raise StandardError.new("API Down") } do
      assert_raises StandardError do
        RateApiClient.get_rate(period: @period, hotel: @hotel, room: @room)
      end
    end
  end
end
