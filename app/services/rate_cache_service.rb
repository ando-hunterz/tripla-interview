class RateCacheService < BaseService
  CACHE_EXPIRY = 5.minutes.to_i

  def initialize
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://redis:6379"))
  end

  def set_rate
    Rails.logger.info("[RateCacheService#set_rate] Syncing all rates from API")
    response = RateApiClient.get_all_rate

    if response.success?
      rates = response.parsed_response['rates'] || []
      for rate in rates
        @redis.set("rate.#{rate['period']}.#{rate['hotel']}.#{rate['room']}", rate['rate'], ex: CACHE_EXPIRY)
      end
      Rails.logger.info("[RateCacheService#set_rate] Successfully synced #{rates.size} rates")
    else
      Rails.logger.error("[RateCacheService#set_rate] API Error: #{response.code} - #{response.message}")
    end
  rescue StandardError => e
    Rails.logger.error("[RateCacheService#set_rate] #{e.class}: #{e.message}")
    raise
  end

  def get_rate(period, hotel, room)
    Rails.logger.info("[RateCacheService.get_rate] Lookup: #{period}.#{hotel}.#{room}")
    
    @redis.get("rate.#{period}.#{hotel}.#{room}")
  rescue StandardError => e
    Rails.logger.error("[RateCacheService.get_rate] #{e.class}: #{e.message}")
    nil
  end

end