# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Citadel Public Articles API', type: :request do
  let!(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, slug: 'test-portal', config: { allowed_locales: %w[en es] }, custom_domain: 'www.example.com') }
  let!(:category) { create(:category, name: 'category', portal: portal, account_id: account.id, locale: 'en', slug: 'category_slug') }
  let!(:article) do
    create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id,
                     content: 'This is a *test* content with ^markdown^', views: 0)
  end

  before do
    ENV['HELPCENTER_URL'] = ENV.fetch('FRONTEND_URL', nil)
    create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id, views: 15)
    create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id, associated_article_id: article.id, views: 1)
  end

  describe 'GET /public/api/v1/portals/:slug/articles' do
    it 'excludes private articles from public portal' do
      # Create a private published article
      private_article = create(:article, category: category, portal: portal, account_id: account.id,
                                         author_id: agent.id, status: :published, private: true)

      get "/hc/#{portal.slug}/#{category.locale}/articles.json"

      expect(response).to have_http_status(:success)
      response_data = JSON.parse(response.body, symbolize_names: true)[:payload]

      # Should not include the private article
      article_ids = response_data.map { |a| a[:id] }
      expect(article_ids).not_to include(private_article.id)

      # Count should only include public articles
      expect(JSON.parse(response.body, symbolize_names: true)[:meta][:articles_count]).to eq(3)
    end
  end

  describe 'GET /public/api/v1/portals/:slug/articles/:id' do
    it 'returns 404 for private articles' do
      private_article = create(:article, category: category, portal: portal, account_id: account.id,
                                         author_id: agent.id, status: :published, private: true)
      get "/hc/#{portal.slug}/articles/#{private_article.slug}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /public/api/v1/portals/:slug/articles/:slug.png (tracking pixel)' do
    it 'returns 404 for private articles tracking pixel' do
      private_article = create(:article, category: category, portal: portal, account_id: account.id,
                                         author_id: agent.id, status: :published, private: true, views: 0)
      get "/hc/#{portal.slug}/articles/#{private_article.slug}.png"

      expect(response).to have_http_status(:not_found)
      expect(private_article.reload.views).to eq 0
    end
  end
end
