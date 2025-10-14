require 'rails_helper'

RSpec.describe 'API Conversations Labels API', type: :request do
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

  before do
    ENV['CITADEL_API_KEY'] = valid_api_key
  end

  describe 'POST #create' do
    context 'with valid API key' do
      it 'adds labels to conversation' do
        post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/labels",
             params: { labels: %w[bug urgent] },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['labels']).to match_array(%w[bug urgent])
        expect(conversation.reload.label_list).to match_array(%w[bug urgent])
      end

      it 'adds to existing labels' do
        conversation.add_labels(['old-label'])

        post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/labels",
             params: { labels: ['new-label'] },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['labels']).to match_array(%w[old-label new-label])
        expect(conversation.reload.label_list).to match_array(%w[old-label new-label])
      end

      it 'does not modify labels when array is empty' do
        conversation.add_labels(%w[label1 label2])

        post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/labels",
             params: { labels: [] },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['labels']).to match_array(%w[label1 label2])
        expect(conversation.reload.label_list).to match_array(%w[label1 label2])
      end

      it 'returns 404 for invalid account_id' do
        post "/api/v1/api/accounts/99999/conversations/#{conversation.display_id}/labels",
             params: { labels: ['test'] },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for non-existent conversation' do
        post "/api/v1/api/accounts/#{account.id}/conversations/999999/labels",
             params: { labels: ['test'] },
             headers: { 'citadel_api_key' => valid_api_key },
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without valid API key' do
      it 'returns unauthorized' do
        post "/api/v1/api/accounts/#{account.id}/conversations/#{conversation.display_id}/labels",
             params: { labels: ['test'] },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
