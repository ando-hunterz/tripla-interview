require "test_helper"

class Api::V1::PricingServiceTest < ActiveSupport::TestCase
  def setup
    @params = { period: "Summer", hotel: "FloatingPointResort", room: "BooleanTwin" }
    @service = Api::V1::PricingService.new(**@params)
  end

  test "run should set result if rate found in cache" do
    mock_cache = Minitest::Mock.new
    mock_cache.expect :get_rate, 100, ["Summer", "FloatingPointResort", "BooleanTwin"]

    RateCacheService.stub :new, mock_cache do
      @service.run
      assert @service.valid?
      assert_equal 100, @service.result
    end

    mock_cache.verify
  end

  test "run should set error if rate not found in cache" do
    mock_cache = Minitest::Mock.new
    mock_cache.expect :get_rate, nil, ["Summer", "FloatingPointResort", "BooleanTwin"]

    RateCacheService.stub :new, mock_cache do
      @service.run
      refute @service.valid?
      assert @service.errors.include?("RATE_NOT_FOUND")
    end

    mock_cache.verify
  end


  test "run should handle unexpected errors" do
    RateCacheService.stub :new, -> { raise StandardError.new("Redis connection failed") } do
      @service.run
      refute @service.valid?
      assert @service.errors.include?("Redis connection failed")
    end
  end
end
