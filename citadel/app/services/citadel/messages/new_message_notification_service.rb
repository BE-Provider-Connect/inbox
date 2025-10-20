# frozen_string_literal: true

module Citadel::Messages::NewMessageNotificationService
  def notify_conversation_assignee
    return if conversation.assignee.blank?
    return if already_notified?(conversation.assignee)
    return if conversation.assignee == sender
    # Don't notify assistants - they don't have notification preferences
    return if conversation.assignee.is_a?(Assistant)

    NotificationBuilder.new(
      notification_type: 'assigned_conversation_new_message',
      user: conversation.assignee,
      account: account,
      primary_actor: message.conversation,
      secondary_actor: message
    ).perform
  end
end
