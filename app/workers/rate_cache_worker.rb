class RateCacheWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3

  def perform
    RateCacheService.new.set_rate
  ensure
    self.class.perform_in(5.minutes)
  end

end
