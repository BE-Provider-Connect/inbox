module CitadelApiAuthHelper
  def authenticate_citadel_api!
    api_key = request.headers['citadel_api_key']

    return render_unauthorized('Missing Citadel API key') if api_key.blank?

    stored_key = ENV.fetch('CITADEL_API_KEY', nil)

    return render_unauthorized('Citadel API key not configured') if stored_key.blank?
    return render_unauthorized('Invalid Citadel API key') unless ActiveSupport::SecurityUtils.secure_compare(api_key, stored_key)

    # Mark this as a system-level API request
    @citadel_api_request = true
  end

  private

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end
end
