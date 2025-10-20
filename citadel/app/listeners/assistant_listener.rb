class AssistantListener < BaseListener
  def assignee_changed(event)
    conversation, account = extract_conversation_and_account(event)

    Rails.logger.info "[AssistantListener] assignee_changed: conversation=#{conversation.id}, assignee_type=#{conversation.assignee_type}"

    # Only trigger if assigned to assistant
    unless conversation.assignee_type == 'Assistant'
      Rails.logger.info '[AssistantListener] Skipping - not assigned to Assistant'
      return
    end

    # Only trigger for verified conversations
    unless conversation_verified?(conversation)
      Rails.logger.info '[AssistantListener] Skipping - conversation not verified'
      return
    end

    Rails.logger.info '[AssistantListener] Triggering webhook for assignee_changed'
    method_name = __method__.to_s
    payload = conversation.webhook_data.merge(
      event: method_name,
      account: account.webhook_data
    )
    process_assistant_webhook(payload, conversation)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]

    # Only trigger if conversation is assigned to Assistant
    return unless message.conversation.assignee_type == 'Assistant'

    # Only trigger for verified conversations
    return unless conversation_verified?(message.conversation)

    # Skip outgoing messages (from assistant itself)
    return if message.outgoing?

    return unless message.webhook_sendable?

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

    AgentBots::WebhookJob.perform_later(assistant.outgoing_url, payload, :assistant_webhook)
  end
end
