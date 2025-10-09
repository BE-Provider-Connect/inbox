module ApiKeyAuthHelper
  extend ActiveSupport::Concern

  private

  def authenticate_api_key!
    api_key = extract_api_key_from_headers

    return if api_key.present? && valid_api_key?(api_key)

    render_unauthorized('Unauthorized')
  end

  def extract_api_key_from_headers
    request.headers['X-API-Key'] ||
      request.headers['Authorization']&.gsub('Bearer ', '')
  end

  def valid_api_key?(api_key)
    # Override this method in the controller if needed for different validation
    api_key == ENV.fetch('CITADEL_API_KEY', nil)
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end
end
