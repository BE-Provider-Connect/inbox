# frozen_string_literal: true

module Citadel::BulkActionsJob
  def bulk_conversation_update
    params = available_params(@params)
    records.each do |conversation|
      bulk_add_labels(conversation)
      bulk_snoozed_until(conversation)
      handle_assignee_update(conversation, params) if params
      conversation.update(params.except(:assignee_id, :assignee_type)) if params
    end
  end

  def handle_assignee_update(conversation, params)
    return unless params.key?(:assignee_id)

    type = (params[:assignee_type] || 'User').to_s.safe_constantize
    id = params[:assignee_id]

    conversation.assignee = if id.nil?
                              nil
                            elsif type == User
                              @account.users.find_by(id: id)
                            elsif type == Assistant
                              # Strip 'assistant_' prefix since frontend sends it with prefix
                              actual_id = id.to_s.sub(/^assistant_/, '')
                              type.find(actual_id)
                            end
  end
end
