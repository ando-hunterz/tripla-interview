class RateCacheWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3

  sidekiq_retry_in do |_count, _exception|
    30
  end

  def perform
    RateCacheService.new.set_rate
  ensure
    self.class.perform_in(5.minutes)
  end

end
