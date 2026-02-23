require "test_helper"

class RateCacheWorkerTest < ActiveSupport::TestCase
  test "perform should call RateCacheService.set_rate and self-schedule" do
    mock_service = Minitest::Mock.new
    mock_service.expect :set_rate, nil

    RateCacheService.stub :new, mock_service do
      RateCacheWorker.stub :perform_in, true do
        RateCacheWorker.new.perform
      end
    end

    mock_service.verify
  end

  test "perform should self-schedule even if set_rate fails" do
    mock_service = Minitest::Mock.new
    mock_service.expect :set_rate, -> { raise StandardError.new("API Error") }

    RateCacheService.stub :new, mock_service do
      RateCacheWorker.stub :perform_in, true do
        RateCacheWorker.new.perform
      end
    end

    mock_service.verify
  end
end
