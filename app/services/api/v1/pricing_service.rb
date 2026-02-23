module Api::V1
  class PricingService < BaseService
    def initialize(period:, hotel:, room:)
      @period = period
      @hotel = hotel
      @room = room
    end

    def run
      rate_cache_service = RateCacheService.new
      rate = rate_cache_service.get_rate(@period, @hotel, @room)

      if rate
        @result = rate
      else
        errors << "RATE_NOT_FOUND"
      end
    rescue StandardError => e
      errors << e.message
    end
  end
end
