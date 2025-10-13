class AssistantListener < BaseListener
  def assignee_changed(event)
    conversation, account = extract_conversation_and_account(event)

    # Only trigger if assigned to assistant
    return unless conversation.assignee_type == 'Assistant'

    # Only trigger for verified conversations
    return unless conversation_verified?(conversation)

    method_name = __method__.to_s
    payload = conversation.webhook_data.merge(
      event: method_name,
      account: account.webhook_data
    )
    process_assistant_webhook(payload, conversation)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]

    Rails.logger.info "[AssistantListener] message_created called for message #{message.id}"
    Rails.logger.info "[AssistantListener] - message_type: #{message.message_type}"
    Rails.logger.info "[AssistantListener] - conversation_id: #{message.conversation_id}"
    Rails.logger.info "[AssistantListener] - conversation assignee_type: #{message.conversation.assignee_type}"
    Rails.logger.info "[AssistantListener] - conversation assignee_id: #{message.conversation.assignee_id}"
    Rails.logger.info "[AssistantListener] - outgoing?: #{message.outgoing?}"
    Rails.logger.info "[AssistantListener] - webhook_sendable?: #{message.webhook_sendable?}"

    # Only trigger if conversation is assigned to Assistant
    unless message.conversation.assignee_type == 'Assistant'
      Rails.logger.info '[AssistantListener] Skipping: conversation not assigned to Assistant'
      return
    end

    # Only trigger for verified conversations
    unless conversation_verified?(message.conversation)
      Rails.logger.info '[AssistantListener] Skipping: conversation not verified'
      return
    end

    # Skip outgoing messages (from assistant itself)
    if message.outgoing?
      Rails.logger.info '[AssistantListener] Skipping: message is outgoing'
      return
    end

    unless message.webhook_sendable?
      Rails.logger.info '[AssistantListener] Skipping: message not webhook_sendable'
      return
    end

    Rails.logger.info "[AssistantListener] Triggering webhook for message #{message.id}"

    method_name = __method__.to_s
    payload = message.webhook_data.merge(event: method_name)
    process_assistant_webhook(payload, message.conversation)
  end

  private

  def conversation_verified?(conversation)
    # Non-web-widget inboxes are always considered verified
    return true unless conversation.inbox.web_widget?

    # For web widgets, check HMAC verification
    conversation.contact_inbox&.hmac_verified || false
  end

  def process_assistant_webhook(payload, _conversation)
    assistant = Assistant.instance
    return if assistant.outgoing_url.blank?

    AgentBots::WebhookJob.perform_later(assistant.outgoing_url, payload)
  end
end
