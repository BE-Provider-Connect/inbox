require 'rails_helper'

RSpec.describe 'API Conversations API', type: :request do
  let(:account) { create(:account) }
  let(:valid_api_key) { 'test-api-key-123' }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:user) { create(:user, account: account) }

  let!(:conversation) do
    create(:conversation,
           account: account,
           inbox: inbox,
           contact: contact,
           contact_inbox: contact_inbox,
           assignee: user,
           status: 'open')
  end

  before do
    ENV['CITADEL_API_KEY'] = valid_api_key
  end

  describe 'GET #show' do
    context 'with valid API key' do
      it 'returns conversation details' do
        get "/api/v1/api/conversations/#{conversation.display_id}",
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['id']).to eq(conversation.id)
        expect(json['status']).to eq('open')
        expect(json['account_id']).to eq(account.id)
      end

      it 'includes conversation meta with sender info' do
        get "/api/v1/api/conversations/#{conversation.display_id}",
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        json = response.parsed_body

        expect(json['meta']).to be_present
        expect(json['meta']['sender']).to be_present
        expect(json['meta']['sender']['id']).to eq(contact.id)
        expect(json['meta']['sender']['email']).to eq(contact.email)
      end

      it 'includes assignee info when present' do
        get "/api/v1/api/conversations/#{conversation.display_id}",
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        json = response.parsed_body

        expect(json['meta']['assignee']).to be_present
        expect(json['meta']['assignee']['id']).to eq(user.id)
        expect(json['meta']['assignee']['name']).to eq(user.name)
      end

      it 'filters by account_id when provided' do
        # Try to find a conversation with wrong account_id filter
        # This tests that display_id + account_id combination works correctly
        get "/api/v1/api/conversations/#{conversation.display_id}",
            params: { account_id: 99_999 },
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for non-existent conversation' do
        get '/api/v1/api/conversations/999999',
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without valid API key' do
      it 'returns unauthorized' do
        get "/api/v1/api/conversations/#{conversation.display_id}",
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #toggle_status' do
    context 'with valid API key' do
      it 'updates conversation status' do
        post "/api/v1/api/conversations/#{conversation.display_id}/toggle_status",
             params: { status: 'resolved' },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['status']).to eq('resolved')
        expect(conversation.reload.status).to eq('resolved')
      end

      it 'toggles status when no status param provided' do
        conversation.update!(status: 'open')

        post "/api/v1/api/conversations/#{conversation.display_id}/toggle_status",
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('resolved')
      end

      it 'filters by account_id when provided' do
        post "/api/v1/api/conversations/#{conversation.display_id}/toggle_status",
             params: { status: 'resolved', account_id: 99_999 },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without valid API key' do
      it 'returns unauthorized' do
        post "/api/v1/api/conversations/#{conversation.display_id}/toggle_status",
             params: { status: 'resolved' },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
