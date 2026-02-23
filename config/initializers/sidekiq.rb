Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://redis:6379") }
end

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://redis:6379") }

  # Start cache warming immediately on startup
  config.on(:startup) do
    RateCacheWorker.perform_async
  end
end

