module AdminTokenAuthenticatable
  extend ActiveSupport::Concern

  included do
    include ActionController::HttpAuthentication::Token::ControllerMethods
    before_action :authenticate_admin!
  end

  private

  def authenticate_admin!
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, admin_token)
    end
  end

  def admin_token
    ENV.fetch("ADMIN_TOKEN", "secret-token")
  end
end
