# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Citadel Articles API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:portal) { create(:portal, account_id: account.id) }
  let(:category) { create(:category, portal: portal) }
  let(:article) { create(:article, account: account, portal: portal, category: category, author_id: agent.id) }

  describe 'POST /api/v1/accounts/{account.id}/portals/{portal.slug}/articles' do
    context 'when it is an authenticated user' do
      it 'creates article with private flag' do
        article_params = {
          article: {
            category_id: category.id,
            description: 'test description',
            title: 'Private Article',
            slug: 'private-article',
            content: 'This is private content.',
            status: :published,
            author_id: agent.id,
            private: true
          }
        }
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
             params: article_params,
             headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eql('Private Article')
        expect(json_response['payload']['private']).to be true
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/portals/{portal.slug}/articles/{article.id}' do
    context 'when it is an authenticated user' do
      it 'updates article private flag' do
        expect(article.private).to be false

        article_params = {
          article: {
            private: true
          }
        }

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            params: article_params,
            headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['private']).to be true

        # Verify it's actually updated in the database
        expect(article.reload.private).to be true
      end

      it 'enables AI agent with organization scope' do
        article_params = {
          article: {
            ai_agent_enabled: true,
            ai_agent_scope: 'organization'
          }
        }

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            params: article_params,
            headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['ai_agent_enabled']).to be true
        expect(json_response['payload']['ai_agent_scope']).to eq('organization')
        expect(article.reload.ai_agent_enabled).to be true
        expect(article.ai_agent_scope).to eq('organization')
      end

      it 'enables AI agent with community_group scope and assigns groups' do
        community_group1 = create(:community_group)
        community_group2 = create(:community_group)

        article_params = {
          article: {
            ai_agent_enabled: true,
            ai_agent_scope: 'community_group',
            community_group_ids: [community_group1.id, community_group2.id]
          }
        }

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            params: article_params,
            headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['ai_agent_enabled']).to be true
        expect(json_response['payload']['ai_agent_scope']).to eq('community_group')
        expect(json_response['payload']['community_groups'].length).to eq(2)

        article.reload
        expect(article.community_groups.pluck(:id)).to contain_exactly(community_group1.id, community_group2.id)
      end

      it 'enables AI agent with community scope and assigns communities' do
        community1 = create(:community)
        community2 = create(:community)

        article_params = {
          article: {
            ai_agent_enabled: true,
            ai_agent_scope: 'community',
            community_ids: [community1.id, community2.id]
          }
        }

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            params: article_params,
            headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['ai_agent_enabled']).to be true
        expect(json_response['payload']['ai_agent_scope']).to eq('community')
        expect(json_response['payload']['communities'].length).to eq(2)

        article.reload
        expect(article.communities.pluck(:id)).to contain_exactly(community1.id, community2.id)
      end

      it 'clears community_groups when switching to community scope' do
        community_group = create(:community_group)
        article.community_groups << community_group
        article.update!(ai_agent_enabled: true, ai_agent_scope: 'community_group')

        community = create(:community)
        article_params = {
          article: {
            ai_agent_scope: 'community',
            community_ids: [community.id]
          }
        }

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            params: article_params,
            headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)

        article.reload
        expect(article.ai_agent_scope).to eq('community')
        expect(article.community_groups).to be_empty
        expect(article.communities.pluck(:id)).to eq([community.id])
      end

      it 'clears communities when switching to community_group scope' do
        community = create(:community)
        article.communities << community
        article.update!(ai_agent_enabled: true, ai_agent_scope: 'community')

        community_group = create(:community_group)
        article_params = {
          article: {
            ai_agent_scope: 'community_group',
            community_group_ids: [community_group.id]
          }
        }

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            params: article_params,
            headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)

        article.reload
        expect(article.ai_agent_scope).to eq('community_group')
        expect(article.communities).to be_empty
        expect(article.community_groups.pluck(:id)).to eq([community_group.id])
      end

      it 'clears both associations when switching to organization scope' do
        community_group = create(:community_group)
        community = create(:community)
        article.communities << community
        article.community_groups << community_group
        article.update!(ai_agent_enabled: true, ai_agent_scope: 'community')

        article_params = {
          article: {
            ai_agent_scope: 'organization'
          }
        }

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            params: article_params,
            headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)

        article.reload
        expect(article.ai_agent_scope).to eq('organization')
        expect(article.communities).to be_empty
        expect(article.community_groups).to be_empty
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/portals/{portal.slug}/articles' do
    context 'when it is an authenticated user' do
      it 'includes both private and public articles for admin' do
        # Force creation of the article from let block
        article
        public_article = create(:article, account_id: account.id, portal: portal, category: category,
                                          author_id: agent.id, private: false)
        private_article = create(:article, account_id: account.id, portal: portal, category: category,
                                           author_id: agent.id, private: true)

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
            headers: admin.create_new_auth_token,
            params: {}
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        # Should include both the original article (which is public) and the new articles
        expect(json_response['payload'].count).to be 3

        article_ids = json_response['payload'].map { |a| a['id'] }
        expect(article_ids).to include(article.id, public_article.id, private_article.id)

        # Check that private flag is included in the response
        private_response = json_response['payload'].find { |a| a['id'] == private_article.id }
        expect(private_response['private']).to be true
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/portals/{portal.slug}/articles/{article.id}' do
    context 'when it is an authenticated user' do
      it 'includes AI agent configuration in response' do
        create(:community_group)
        community = create(:community)
        article2 = create(:article, account_id: account.id, portal: portal, category: category, author_id: agent.id)
        article2.communities << community
        article2.update!(ai_agent_enabled: true, ai_agent_scope: 'community')

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article2.id}",
            headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response['payload']['ai_agent_enabled']).to be true
        expect(json_response['payload']['ai_agent_scope']).to eq('community')
        expect(json_response['payload']['communities'].length).to eq(1)
        expect(json_response['payload']['communities'].first['id']).to eq(community.id)
        expect(json_response['payload']['community_groups']).to be_empty
      end
    end
  end
end
