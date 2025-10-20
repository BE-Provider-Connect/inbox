json.id @conversation.id
json.account_id @conversation.account_id
json.inbox_id @conversation.inbox_id
json.status @conversation.status
json.uuid @conversation.uuid
json.created_at @conversation.created_at.to_i
json.updated_at @conversation.updated_at.to_i
json.last_activity_at @conversation.last_activity_at.to_i

json.meta do
  json.sender do
    json.id @conversation.contact.id
    json.name @conversation.contact.name
    json.email @conversation.contact.email
    json.phone_number @conversation.contact.phone_number
  end

  if @conversation.assignee.present?
    json.assignee do
      json.id @conversation.assignee.id
      json.name @conversation.assignee.name
      json.type @conversation.assignee.class.name
    end
  end
end
