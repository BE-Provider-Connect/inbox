require 'rails_helper'

RSpec.describe 'API Conversations Assignments API', type: :request do
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
           contact_inbox: contact_inbox)
  end

  before do
    ENV['CITADEL_API_KEY'] = valid_api_key
  end

  describe 'POST #create' do
    context 'with valid API key' do
      it 'assigns conversation to user' do
        post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/assignments",
             params: { assignee_id: user.id },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['assignee_id']).to eq(user.id)
        expect(conversation.reload.assignee_id).to eq(user.id)
      end

      it 'unassigns conversation when assignee_id is null' do
        conversation.update!(assignee: user)

        post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/assignments",
             params: { assignee_id: nil },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['assignee_id']).to be_nil
        expect(conversation.reload.assignee_id).to be_nil
      end

      it 'reassigns conversation to different user' do
        another_user = create(:user, account: account)
        conversation.update!(assignee: user)

        post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/assignments",
             params: { assignee_id: another_user.id },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['assignee_id']).to eq(another_user.id)
        expect(conversation.reload.assignee_id).to eq(another_user.id)
      end

      it 'returns 404 for invalid account_id' do
        post "/api/v1/api/accounts/99999/conversations/#{conversation.display_id}/assignments",
             params: { assignee_id: user.id },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for non-existent conversation' do
        post "/api/v1/api/accounts/#{account.id}/conversations/999999/assignments",
             params: { assignee_id: user.id },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'does not assign user from different account' do
        other_account = create(:account)
        other_user = create(:user, account: other_account)

        post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/assignments",
             params: { assignee_id: other_user.id },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee_id).to be_nil
      end
    end

    context 'without valid API key' do
      it 'returns unauthorized' do
        post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/assignments",
             params: { assignee_id: user.id },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
