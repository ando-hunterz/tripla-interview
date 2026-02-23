Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://redis:6379") }
end

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://redis:6379") }

  # 3 seconds waiting time, as we need to wait for the api to startup
  config.on(:startup) do
    RateCacheWorker.perform_in(3.seconds)
  end
end

