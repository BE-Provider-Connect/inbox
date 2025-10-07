require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Articles', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let!(:portal) { create(:portal, name: 'test_portal', account_id: account.id) }
  let!(:category) { create(:category, name: 'category', portal: portal, account_id: account.id, locale: 'en', slug: 'category_slug') }
  let!(:article) { create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id) }

  describe 'POST /api/v1/accounts/{account.id}/portals/{portal.slug}/articles' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates article' do
        article_params = {
          article: {
            category_id: category.id,
            description: 'test description',
            title: 'MyTitle',
            slug: 'my-title',
            content: 'This is my content.',
            status: :published,
            author_id: agent.id,
            position: 3
          }
        }
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
             params: article_params,
             headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eql('MyTitle')
        expect(json_response['payload']['status']).to eql('draft')
        expect(json_response['payload']['position']).to be(3)
      end

      it 'creates article even if category is not provided' do
        article_params = {
          article: {
            category_id: nil,
            description: 'test description',
            title: 'MyTitle',
            slug: 'my-title',
            content: 'This is my content.',
            status: :published,
            author_id: agent.id,
            position: 3
          }
        }
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
             params: article_params,
             headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eql('MyTitle')
        expect(json_response['payload']['status']).to eql('draft')
        expect(json_response['payload']['position']).to be(3)
      end

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

      it 'associate to the root article' do
        root_article = create(:article, category: category, slug: 'root-article', portal: portal, account_id: account.id, author_id: agent.id,
                                        associated_article_id: nil)
        parent_article = create(:article, category: category, slug: 'parent-article', portal: portal, account_id: account.id, author_id: agent.id,
                                          associated_article_id: root_article.id)

        article_params = {
          article: {
            category_id: category.id,
            description: 'test description',
            title: 'MyTitle',
            slug: 'MyTitle',
            content: 'This is my content.',
            status: :published,
            author_id: agent.id,
            associated_article_id: parent_article.id
          }
        }
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
             params: article_params,
             headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eql('MyTitle')

        category = Article.find(json_response['payload']['id'])
        expect(category.associated_article_id).to eql(root_article.id)
      end

      it 'associate to the current parent article' do
        parent_article = create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id, associated_article_id: nil)

        article_params = {
          article: {
            category_id: category.id,
            description: 'test description',
            title: 'MyTitle',
            slug: 'MyTitle',
            content: 'This is my content.',
            status: :published,
            author_id: agent.id,
            associated_article_id: parent_article.id
          }
        }
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
             params: article_params,
             headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eql('MyTitle')

        category = Article.find(json_response['payload']['id'])
        expect(category.associated_article_id).to eql(parent_article.id)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/portals/{portal.slug}/articles/{article.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates article' do
        article_params = {
          article: {
            title: 'MyTitle2',
            status: 'published',
            description: 'test_description',
            position: 5
          }
        }

        expect(article.title).not_to eql(article_params[:article][:title])

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            params: article_params,
            headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eql(article_params[:article][:title])
        expect(json_response['payload']['status']).to eql(article_params[:article][:status])
        expect(json_response['payload']['position']).to eql(article_params[:article][:position])
      end

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

  describe 'DELETE /api/v1/accounts/{account.id}/portals/{portal.slug}/articles/{article.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes category' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
               headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        deleted_article = Article.find_by(id: article.id)
        expect(deleted_article).to be_nil
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/portals/{portal.slug}/articles' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'get all articles' do
        article2 = create(:article, account_id: account.id, portal: portal, category: category, author_id: agent.id)
        expect(article2.id).not_to be_nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
            headers: admin.create_new_auth_token,
            params: {}
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload'].count).to be 2
      end

      it 'get all articles with uncategorized articles' do
        article2 = create(:article, account_id: account.id, portal: portal, category: nil, locale: 'en', author_id: agent.id)
        expect(article2.id).not_to be_nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
            headers: admin.create_new_auth_token,
            params: {}
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload'].count).to be 2
        expect(json_response['payload'][0]['id']).to eq article2.id
        expect(json_response['payload'][0]['category']['id']).to be_nil
      end

      it 'get all articles with searched params' do
        article2 = create(:article, account_id: account.id, portal: portal, category: category, author_id: agent.id)
        expect(article2.id).not_to be_nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
            headers: admin.create_new_auth_token,
            params: { category_slug: category.slug }
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload'].count).to be 2
      end

      it 'get all articles with searched text query' do
        article2 = create(:article,
                          account_id: account.id,
                          portal: portal,
                          category: category,
                          author_id: agent.id,
                          content: 'this is some test and funny content')
        expect(article2.id).not_to be_nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
            headers: admin.create_new_auth_token,
            params: { query: 'funny' }
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload'].count).to be 1
        expect(json_response['meta']['all_articles_count']).to be 2
        expect(json_response['meta']['articles_count']).to be 1
        expect(json_response['meta']['mine_articles_count']).to be 0
      end

      it 'includes both private and public articles for admin' do
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

    describe 'GET /api/v1/accounts/{account.id}/portals/{portal.slug}/articles/{article.id}' do
      it 'get article' do
        article2 = create(:article, account_id: account.id, portal: portal, category: category, author_id: agent.id)
        expect(article2.id).not_to be_nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article2.id}",
            headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response['payload']['title']).to eq(article2.title)
        expect(json_response['payload']['id']).to eq(article2.id)
      end

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

      it 'get associated articles' do
        root_article = create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id, associated_article_id: nil)
        child_article_1 = create(:article, slug: 'child-1', category: category, portal: portal, account_id: account.id, author_id: agent.id,
                                           associated_article_id: root_article.id)
        child_article_2 = create(:article, slug: 'child-2', category: category, portal: portal, account_id: account.id, author_id: agent.id,
                                           associated_article_id: root_article.id)

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{root_article.id}",
            headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response['payload']['associated_articles'].length).to eq(2)
        associated_articles_ids = json_response['payload']['associated_articles'].pluck('id')
        expect(associated_articles_ids).to contain_exactly(child_article_1.id, child_article_2.id)
        expect(json_response['payload']['id']).to eq(root_article.id)
      end
    end
  end
end
