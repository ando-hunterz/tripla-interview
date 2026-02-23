require "sidekiq/api"

module Admin
  class RateCacheController < ApplicationController
    include AdminTokenAuthenticatable

    def refresh
      # Reset the Queue
      Sidekiq::Queue.new.clear
      Sidekiq::ScheduledSet.new.clear
      Sidekiq::RetrySet.new.clear
      
      RateCacheService.new.set_rate
      
      RateCacheWorker.perform_in(5.minutes)
      render json: { message: "Rate cache refreshed and Sidekiq queues cleared" }, status: :ok
    rescue StandardError => e
      render json: { error: "Failed to refresh cache or reset Sidekiq: #{e.message}" }, status: :internal_server_error
    end
  end
end
