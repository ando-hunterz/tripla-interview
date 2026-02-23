class Api::V1::PricingController < ApplicationController
  include PricingConstants

  before_action :validate_params

  def index
    period = params[:period]
    hotel  = params[:hotel]
    room   = params[:room]

    Rails.logger.info("[Api::V1::PricingController] Request for pricing for: #{period}.#{hotel}.#{room}")
    service = Api::V1::PricingService.new(period:, hotel:, room:)
    service.run

    if service.valid?
      render json: { rate: service.result }
    else
      if service.errors.include?('RATE_NOT_FOUND')
        format_error(code: 'RATE_NOT_FOUND', message: 'Rate not found', status: :not_found)
      else
        format_error(code: 'INTERNAL_ERROR', message: service.errors.join(', '))
      end
    end
  rescue StandardError => e
    format_error(code: 'INTERNAL_ERROR', message: e.message, status: :internal_server_error)
  end


  private
  def validate_params
    # Validate required parameters
    unless params[:period].present? && params[:hotel].present? && params[:room].present?
      return format_error(code: 'MISSING_PARAMETERS', message: "Missing required parameters: period, hotel, room")
    end

    # Validate parameter values
    unless VALID_PERIODS.include?(params[:period])
      return format_error(code: 'INVALID_PERIOD', message: "Invalid period. Must be one of: #{VALID_PERIODS.join(', ')}")
    end

    unless VALID_HOTELS.include?(params[:hotel])
      return format_error(code: 'INVALID_HOTEL', message: "Invalid hotel. Must be one of: #{VALID_HOTELS.join(', ')}")
    end

    unless VALID_ROOMS.include?(params[:room])
      return format_error(code: 'INVALID_ROOM', message: "Invalid room. Must be one of: #{VALID_ROOMS.join(', ')}")
    end
  end

  def format_error(code:, message:, status: :bad_request)
    render json: {
      error: {
        code: code,
        message: message
      }
    }, status: status
  end

end

