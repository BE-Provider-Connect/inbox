require 'rails_helper'

RSpec.describe 'Communities API', type: :request do
  let!(:account) { create(:account) }
  let!(:community_group) { create(:community_group) }
  let!(:community) { create(:community, community_group: community_group) }

  describe 'GET /api/v1/accounts/{account.id}/communities' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/communities"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns all communities' do
        create_list(:community, 2)

        get "/api/v1/accounts/#{account.id}/communities",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response.length).to eq(3) # 1 from let! + 2 from create_list
        expect(json_response.first.keys).to include('id', 'external_id', 'name', 'community_group_id', 'synced_at')
      end

      it 'filters communities by community_group_id' do
        other_group = create(:community_group)
        community_in_group = create(:community, community_group: community_group)
        community_in_other_group = create(:community, community_group: other_group)

        get "/api/v1/accounts/#{account.id}/communities",
            headers: admin.create_new_auth_token,
            params: { community_group_id: community_group.id },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        community_ids = json_response.map { |c| c['id'] }
        expect(community_ids).to include(community.id, community_in_group.id)
        expect(community_ids).not_to include(community_in_other_group.id)
      end

      it 'includes community_group information' do
        get "/api/v1/accounts/#{account.id}/communities",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        community_with_group = json_response.find { |c| c['id'] == community.id }
        expect(community_with_group['community_group']).to be_present
        expect(community_with_group['community_group']['id']).to eq(community_group.id)
        expect(community_with_group['community_group']['name']).to eq(community_group.name)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/communities/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/communities/#{community.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'shows the community' do
        get "/api/v1/accounts/#{account.id}/communities/#{community.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(community.id)
        expect(json_response['name']).to eq(community.name)
        expect(json_response['external_id']).to eq(community.external_id)
      end

      it 'includes community_group information' do
        get "/api/v1/accounts/#{account.id}/communities/#{community.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['community_group']).to be_present
        expect(json_response['community_group']['id']).to eq(community_group.id)
        expect(json_response['community_group']['name']).to eq(community_group.name)
      end

      it 'handles community without a group' do
        standalone_community = create(:community, community_group: nil)

        get "/api/v1/accounts/#{account.id}/communities/#{standalone_community.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(standalone_community.id)
        expect(json_response['community_group_id']).to be_nil
      end
    end
  end
end
