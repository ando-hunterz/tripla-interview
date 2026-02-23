require "test_helper"

class RateCacheWorkerTest < ActiveSupport::TestCase
  def setup
    @worker = RateCacheWorker.new
  end

  test "retry option is set to 3" do
    assert_equal 3, RateCacheWorker.sidekiq_options["retry"]
  end

  test "retry delay is constant 30 seconds" do
    # Testing the sidekiq_retry_in block
    # sidekiq_retry_in is stored in sidekiq_retry_in_block
    retry_in_block = RateCacheWorker.sidekiq_retry_in_block
    assert_not_nil retry_in_block
    
    # It should return 30 regardless of count or exception
    assert_equal 30, retry_in_block.call(0, StandardError.new)
    assert_equal 30, retry_in_block.call(5, StandardError.new)
    assert_equal 30, retry_in_block.call(10, nil)
  end

  test "perform calls RateCacheService" do
    service_mock = Minitest::Mock.new
    service_mock.expect :set_rate, nil

    RateCacheService.stub :new, service_mock do
      # We need to stub perform_in to avoid actually scheduling a job
      RateCacheWorker.stub :perform_in, nil do
        @worker.perform
      end
    end

    assert_mock service_mock
  end

  test "perform schedules next run in 5 minutes" do
    service_mock = Minitest::Mock.new
    service_mock.expect :set_rate, nil

    RateCacheService.stub :new, service_mock do
      mock_perform_in = Minitest::Mock.new
      mock_perform_in.expect :call, nil, [5.minutes]

      RateCacheWorker.stub :perform_in, mock_perform_in do
        @worker.perform
      end

      assert_mock mock_perform_in
    end
  end
end
