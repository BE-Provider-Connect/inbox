module CitadelApiAuthHelper
  def authenticate_citadel_api!
    api_key = request.headers[:citadel_api_key] || request.headers[:HTTP_CITADEL_API_KEY]

    if api_key.blank?
      render_unauthorized('Missing Citadel API key')
      return
    end

    stored_key = ENV.fetch('CITADEL_API_KEY', nil)

    if stored_key.blank?
      render_unauthorized('Citadel API key not configured')
      return
    end

    unless ActiveSupport::SecurityUtils.secure_compare(api_key, stored_key)
      render_unauthorized('Invalid Citadel API key')
      return
    end

    # Mark this as a system-level API request
    @citadel_api_request = true
  end

  private

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end
end
