class Webhooks::Trigger
  SUPPORTED_ERROR_HANDLE_EVENTS = %w[message_created message_updated].freeze

  def initialize(url, payload, webhook_type)
    @url = url
    @payload = payload
    @webhook_type = webhook_type
  end

  def self.execute(url, payload, webhook_type)
    new(url, payload, webhook_type).execute
  end

  def execute
    perform_request
  rescue StandardError => e
    handle_error(e)
    Rails.logger.warn "Exception: Invalid webhook URL #{@url} : #{e.message}"
  end

  private

  def perform_request
    headers = { content_type: :json, accept: :json }

    # Add API key header only for Assistant webhooks going to Citadel
    headers['X-Api-Key'] = ENV.fetch('CITADEL_API_KEY', nil) if assistant_webhook_to_citadel?

    RestClient::Request.execute(
      method: :post,
      url: @url,
      payload: @payload.to_json,
      headers: headers,
      timeout: 5
    )
  end

  def assistant_webhook_to_citadel?
    citadel_webhook_url = ENV.fetch('CITADEL_API_WEBHOOK_URL', nil)
    return false if citadel_webhook_url.blank?

    @webhook_type == :assistant_webhook && @url.start_with?(citadel_webhook_url)
  end

  def handle_error(error)
    return unless should_handle_error?
    return unless message

    update_message_status(error)
  end

  def should_handle_error?
    @webhook_type == :api_inbox_webhook && SUPPORTED_ERROR_HANDLE_EVENTS.include?(@payload[:event])
  end

  def update_message_status(error)
    Messages::StatusUpdateService.new(message, 'failed', error.message).perform
  end

  def message
    return if message_id.blank?

    @message ||= Message.find_by(id: message_id)
  end

  def message_id
    @payload[:id]
  end
end
