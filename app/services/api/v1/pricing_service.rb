module Api::V1
  class PricingService < BaseService
    def initialize(period:, hotel:, room:)
      @period = period
      @hotel = hotel
      @room = room
    end

    def run
      Rails.logger.info("[Api::V1::PricingService] Pricing Lookup: #{@period}.#{@hotel}.#{@room}")
      rate_cache_service = RateCacheService.new
      rate = rate_cache_service.get_rate(@period, @hotel, @room)

      Rails.logger.info("[Api::V1::PricingService] Pricing Result for #{@period}.#{@hotel}.#{@room}: #{rate}")
      if rate
        @result = rate
      else
        Rails.logger.info("[Api::V1::PricingService] Pricing Result for #{@period}.#{@hotel}.#{@room}: #{rate}")
        errors << "RATE_NOT_FOUND"
      end
    rescue StandardError => e
      Rails.logger.info("[Api::V1::PricingService] Pricing Result for #{@period}.#{@hotel}.#{@room}: #{rate}")
      errors << e.message
    end
  end
end
