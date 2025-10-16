json.payload do
  json.array! @messages do |message|
    json.id message.id
    json.content message.content
    json.message_type message.message_type_before_type_cast
    json.private message.private
    json.created_at message.created_at.to_i

    if message.sender
      json.sender do
        json.id message.sender.id
        json.name message.sender.name
        json.type message.sender.class.name
      end
    end
  end
end
