require "sidekiq/api"

module Admin
  class RateCacheController < ApplicationController
    include AdminTokenAuthenticatable

    def refresh
      Rails.logger.info("[Admin::RateCacheController] Begin Resetting Rate Cache")
      # Reset the Queue
      Sidekiq::Queue.new.clear
      Sidekiq::ScheduledSet.new.clear
      Sidekiq::RetrySet.new.clear
      
      Rails.logger.info("[Admin::RateCacheController] Sidekiq queues cleared, Now Reseting Rate Cache")
      RateCacheService.new.set_rate
      
      Rails.logger.info("[Admin::RateCacheController] Rate Cache Reset, Scheduling Next Run")
      RateCacheWorker.perform_in(5.minutes)
      render json: { message: "Rate cache refreshed and Sidekiq queues cleared" }, status: :ok
    rescue StandardError => e
      render json: { error: "Failed to refresh cache or reset Sidekiq: #{e.message}" }, status: :internal_server_error
    end
  end
end
