json.payload do
  if @conversation.assignee.present?
    # Determine which partial to use based on assignee_type, not the object's class
    partial_name = @conversation.assignee_type == 'Assistant' ? 'api/v1/models/assistant' : 'api/v1/models/agent'

    json.assignee do
      json.partial! partial_name, formats: [:json], resource: @conversation.assignee
    end
  else
    json.assignee nil
  end
  json.conversation_id @conversation.display_id
end
