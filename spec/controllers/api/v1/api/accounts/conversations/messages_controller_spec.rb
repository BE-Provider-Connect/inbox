require 'rails_helper'

RSpec.describe 'API Conversations Messages API', type: :request do
  let(:account) { create(:account) }
  let(:valid_api_key) { 'test-api-key-123' }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }

  let!(:conversation) do
    create(:conversation,
           account: account,
           inbox: inbox,
           contact: contact,
           contact_inbox: contact_inbox)
  end

  let!(:incoming_message) do
    create(:message,
           conversation: conversation,
           account: account,
           inbox: inbox,
           sender: contact,
           message_type: :incoming,
           content: 'Hello')
  end

  let!(:outgoing_message) do
    create(:message,
           conversation: conversation,
           account: account,
           inbox: inbox,
           message_type: :outgoing,
           content: 'Hi there')
  end

  before do
    ENV['CITADEL_API_KEY'] = valid_api_key
  end

  describe 'GET #index' do
    context 'with valid API key' do
      it 'returns all messages for conversation' do
        get "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        # The conversation may have activity messages in addition to the test messages
        message_ids = json['payload'].map { |m| m['id'] }
        expect(message_ids).to include(incoming_message.id)
        expect(message_ids).to include(outgoing_message.id)
      end

      it 'includes message details' do
        get "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        json = response.parsed_body
        message_json = json['payload'].first

        expect(message_json).to have_key('id')
        expect(message_json).to have_key('content')
        expect(message_json).to have_key('message_type')
        expect(message_json).to have_key('created_at')
        expect(message_json).to have_key('sender')
      end

      it 'orders messages by created_at' do
        get "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        json = response.parsed_body

        expect(json['payload'].first['id']).to eq(incoming_message.id)
        expect(json['payload'].last['id']).to eq(outgoing_message.id)
      end

      it 'returns 404 for invalid account_id' do
        get "/api/v1/api/accounts/99999/conversations/#{conversation.display_id}/messages",
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for non-existent conversation' do
        get "/api/v1/api/accounts/#{account.id}/conversations/999999/messages",
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without valid API key' do
      it 'returns unauthorized' do
        get "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #create' do
    context 'with valid API key' do
      it 'creates a new message' do
        expect do
          post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
               params: {
                 content: 'New message',
                 message_type: 'outgoing'
               },
               headers: { 'citadel_api_key' => valid_api_key },
               as: :json
        end.to change(Message, :count).by(1)

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['content']).to eq('New message')
        expect(json['message_type']).to eq(1) # outgoing
      end

      it 'creates private message when private param is true' do
        post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
             params: {
               content: 'Private note',
               message_type: 'outgoing',
               private: true
             },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:success)

        message = Message.last
        expect(message.private).to be true
        expect(message.content).to eq('Private note')
      end

      it 'returns 404 for invalid account_id' do
        post "/api/v1/api/accounts/99999/conversations/#{conversation.display_id}/messages",
             params: {
               content: 'Test message',
               message_type: 'outgoing'
             },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for non-existent conversation' do
        post "/api/v1/api/accounts/#{account.id}/conversations/999999/messages",
             params: {
               content: 'Test message',
               message_type: 'outgoing'
             },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without valid API key' do
      it 'returns unauthorized' do
        post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
             params: {
               content: 'New message',
               message_type: 'outgoing'
             },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
