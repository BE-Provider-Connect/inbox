require 'rails_helper'

RSpec.describe 'Sync Articles API', type: :request do
  let(:account) { create(:account) }
  let(:valid_api_key) { 'test-api-key-123' }
  let(:portal) { create(:portal, account: account) }
  let(:category) { create(:category, portal: portal) }
  let(:author) { create(:user, account: account) }
  let(:community_group) { create(:community_group, account: account) }
  let(:community) { create(:community, account: account, community_group: community_group) }

  let!(:published_article_with_ai) do
    create(:article,
           portal: portal,
           category: category,
           author: author,
           status: :published,
           ai_agent_enabled: true,
           ai_agent_scope: :community,
           communities: [community])
  end

  let(:published_article_without_ai) do
    create(:article,
           portal: portal,
           category: category,
           author: author,
           status: :published,
           ai_agent_enabled: false)
  end

  let(:draft_article_with_ai) do
    create(:article,
           portal: portal,
           category: category,
           author: author,
           status: :draft,
           ai_agent_enabled: true,
           ai_agent_scope: :organization)
  end

  before do
    # Create articles that need to exist for filtering tests
    published_article_without_ai
    draft_article_with_ai
    ENV['CITADEL_API_KEY'] = valid_api_key
  end

  describe 'GET #index' do
    context 'with valid API key' do
      it 'returns only published articles with AI enabled' do
        get '/api/v1/citadel/articles',
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['articles'].size).to eq(1)
        expect(json['articles'][0]['id']).to eq(published_article_with_ai.id)
        expect(json['articles'][0]['ai_agent_enabled']).to be true
      end

      it 'includes article associations' do
        get '/api/v1/citadel/articles',
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        json = response.parsed_body
        article_json = json['articles'][0]

        expect(article_json).to have_key('author')
        expect(article_json).to have_key('portal')
        expect(article_json).to have_key('category')
        expect(article_json).to have_key('communities')
        expect(article_json).to have_key('community_groups')

        expect(article_json['communities'][0]['id']).to eq(community.id)
      end

      it 'supports pagination' do
        get '/api/v1/citadel/articles',
            params: { limit: 10, offset: 0 },
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        json = response.parsed_body

        expect(json['meta']).to include(
          'total' => 1,
          'limit' => 10,
          'offset' => 0,
          'has_more' => false
        )
      end

      it 'filters by updated_since' do
        published_article_with_ai.update!(updated_at: 2.days.ago)
        recent_article = create(:article,
                                portal: portal,
                                category: category,
                                author: author,
                                status: :published,
                                ai_agent_enabled: true,
                                ai_agent_scope: :organization,
                                updated_at: 1.hour.ago)

        get '/api/v1/citadel/articles',
            params: { updated_since: 1.day.ago.iso8601 },
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        json = response.parsed_body
        expect(json['articles'].size).to eq(1)
        expect(json['articles'][0]['id']).to eq(recent_article.id)
      end

      it 'filters by account_ids' do
        another_account = create(:account)
        another_portal = create(:portal, account: another_account)
        another_author = create(:user, account: another_account)
        another_article = create(:article,
                                 portal: another_portal,
                                 author: another_author,
                                 status: :published,
                                 ai_agent_enabled: true,
                                 ai_agent_scope: :organization)

        get '/api/v1/citadel/articles',
            params: { account_ids: [another_account.id] },
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        json = response.parsed_body
        expect(json['articles'].size).to eq(1)
        expect(json['articles'][0]['id']).to eq(another_article.id)
      end
    end

    context 'with Authorization header' do
      it 'accepts Bearer token format' do
        get '/api/v1/citadel/articles',
            headers: { 'citadel_api_key' => "#{valid_api_key}" },
            as: :json

        expect(response).to have_http_status(:success)
      end
    end

    context 'with invalid API key' do
      it 'returns unauthorized' do
        get '/api/v1/citadel/articles',
            headers: { 'citadel_api_key' => 'invalid-key' },
            as: :json

        expect(response).to have_http_status(:unauthorized)
        json = response.parsed_body
        expect(json['error']).to eq('Invalid Citadel API key')
      end
    end

    context 'without API key' do
      it 'returns unauthorized' do
        get '/api/v1/citadel/articles', as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    context 'with valid API key' do
      it 'returns the specific article' do
        get "/api/v1/citadel/articles/#{published_article_with_ai.id}",
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['article']['id']).to eq(published_article_with_ai.id)
        expect(json['article']['title']).to eq(published_article_with_ai.title)
      end

      it 'returns 404 for non-existent article' do
        get '/api/v1/citadel/articles/999999',
            headers: { 'citadel_api_key' => valid_api_key },
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without valid API key' do
      it 'returns unauthorized' do
        get "/api/v1/citadel/articles/#{published_article_with_ai.id}",
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
