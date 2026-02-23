require "sidekiq/api"

module Admin
  class RateCacheController < ApplicationController
    include AdminTokenAuthenticatable

    MAX_RETRIES = 3
    
    def refresh
      Rails.logger.info("[Admin::RateCacheController] Begin Resetting Rate Cache")
      
      retries = 0
      begin
        RateCacheService.new.set_rate
      rescue StandardError => e
        retries += 1
        if retries < MAX_RETRIES
          Rails.logger.warn("[Admin::RateCacheController] RateCacheService.set_rate failed (Attempt #{retries}/#{MAX_RETRIES}). Retrying in 1 second... Error: #{e.message}")
          sleep 1
          retry
        else
          Rails.logger.error("[Admin::RateCacheController] RateCacheService.set_rate failed after #{MAX_RETRIES} attempts. Error: #{e.message}")
          raise e
        end
      end

      Rails.logger.info("[Admin::RateCacheController] Resetting Cache Completed, now Resetting Queues")
      # Reset the Queue
      Sidekiq::Queue.new.clear
      Sidekiq::ScheduledSet.new.clear
      Sidekiq::RetrySet.new.clear
      
      Rails.logger.info("[Admin::RateCacheController] Rate Cache Reset, Scheduling Next Run")
      RateCacheWorker.perform_in(5.minutes)
      render json: { message: "Rate cache refreshed and Sidekiq queues cleared" }, status: :ok
    rescue StandardError => e
      render json: { error: "Failed to refresh cache or reset Sidekiq: #{e.message}" }, status: :internal_server_error
    end
  end
end
