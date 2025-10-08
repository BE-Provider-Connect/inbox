require 'rails_helper'

RSpec.describe 'Community Groups API', type: :request do
  let!(:account) { create(:account) }
  let!(:community_group) { create(:community_group, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/community_groups' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/community_groups"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns all community groups' do
        create_list(:community_group, 2, account: account)

        get "/api/v1/accounts/#{account.id}/community_groups",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response.length).to eq(3) # 1 from let! + 2 from create_list
        expect(json_response.first.keys).to include('id', 'external_id', 'name', 'synced_at')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/community_groups/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/community_groups/#{community_group.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'shows the community group' do
        get "/api/v1/accounts/#{account.id}/community_groups/#{community_group.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(community_group.id)
        expect(json_response['name']).to eq(community_group.name)
        expect(json_response['external_id']).to eq(community_group.external_id)
      end

      it 'includes associated communities' do
        community1 = create(:community, community_group: community_group, account: account)
        community2 = create(:community, community_group: community_group, account: account)

        get "/api/v1/accounts/#{account.id}/community_groups/#{community_group.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['communities'].length).to eq(2)
        community_ids = json_response['communities'].map { |c| c['id'] }
        expect(community_ids).to contain_exactly(community1.id, community2.id)
      end
    end
  end
end
