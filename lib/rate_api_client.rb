class RateApiClient
  include HTTParty
  base_uri ENV.fetch('RATE_API_URL', 'http://localhost:8080')
  headers "Content-Type" => "application/json"
  headers 'token' => ENV.fetch('RATE_API_TOKEN', '04aa6f42aa03f220c2ae9a276cd68c62')

  def self.get_rate(period:, hotel:, room:)
    params = {
      attributes: [
        {
          period: period,
          hotel: hotel,
          room: room
        }
      ]
    }.to_json
    self.post("/pricing", body: params)
  rescue StandardError => e
    Rails.logger.error("[RateApiClient#get_rate] #{e.class}: #{e.message}")
    raise
  end

  def self.get_all_rate
    attributes = PricingConstants::VALID_PERIODS.flat_map do |period|
      PricingConstants::VALID_HOTELS.flat_map do |hotel|
        PricingConstants::VALID_ROOMS.map do |room|
          { period: period, hotel: hotel, room: room }
        end
      end
    end

    params = { attributes: attributes }.to_json
    self.post("/pricing", body: params)
  rescue StandardError => e
    Rails.logger.error("[RateApiClient#get_all_rate] #{e.class}: #{e.message}")
    raise
  end
end
