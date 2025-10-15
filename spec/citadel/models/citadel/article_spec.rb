# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Article, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:portal_1) { create(:portal, account_id: account.id, config: { allowed_locales: %w[en es] }) }
  let(:category_1) { create(:category, slug: 'category_1', locale: 'en', portal_id: portal_1.id) }

  describe 'associations' do
    it { expect(Article.new).to have_many(:article_community_groups).dependent(:destroy) }
    it { expect(Article.new).to have_many(:community_groups).through(:article_community_groups) }
    it { expect(Article.new).to have_many(:article_communities).dependent(:destroy) }
    it { expect(Article.new).to have_many(:communities).through(:article_communities) }
  end

  describe 'private field' do
    let(:article) { create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id) }

    it 'defaults to false' do
      expect(article.private).to be false
    end

    it 'can be set to true' do
      article.update!(private: true)
      expect(article.reload.private).to be true
    end
  end

  describe '.public_articles scope' do
    let!(:public_article) { create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id, private: false) }
    let!(:private_article) { create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id, private: true) }

    it 'returns only non-private articles' do
      public_articles = described_class.public_articles
      expect(public_articles).to include(public_article)
      expect(public_articles).not_to include(private_article)
    end

    it 'works with other scopes' do
      public_article.update!(status: :published)
      private_article.update!(status: :published)

      published_public = described_class.published.public_articles
      expect(published_public).to include(public_article)
      expect(published_public).not_to include(private_article)
    end
  end

  describe '.search_by_privacy scope' do
    let!(:public_article) { create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id, private: false) }
    let!(:private_article) { create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id, private: true) }

    it 'filters by public articles when privacy is public' do
      articles = Article.search_by_privacy('public')
      expect(articles).to include(public_article)
      expect(articles).not_to include(private_article)
    end

    it 'filters by private articles when privacy is private' do
      articles = Article.search_by_privacy('private')
      expect(articles).to include(private_article)
      expect(articles).not_to include(public_article)
    end

    it 'returns all articles when privacy is nil or blank' do
      articles = Article.search_by_privacy(nil)
      expect(articles).to include(public_article, private_article)

      articles = Article.search_by_privacy('')
      expect(articles).to include(public_article, private_article)
    end
  end

  describe 'AI Agent features' do
    context 'when filtering by AI configuration' do
      let!(:ai_enabled_article) do
        create(:article, category_id: category_1.id, portal_id: portal_1.id, author_id: user.id,
                         ai_agent_enabled: true, ai_agent_scope: 'organization')
      end
      let!(:ai_disabled_article) do
        create(:article, category_id: category_1.id, portal_id: portal_1.id, author_id: user.id,
                         ai_agent_enabled: false)
      end
      let!(:community_group) { create(:community_group, account: account) }
      let!(:community) { create(:community, account: account) }
      let!(:ai_group_article) do
        article = create(:article, category_id: category_1.id, portal_id: portal_1.id, author_id: user.id)
        article.community_groups << community_group
        article.update!(ai_agent_enabled: true, ai_agent_scope: 'community_group')
        article
      end
      let!(:ai_community_article) do
        article = create(:article, category_id: category_1.id, portal_id: portal_1.id, author_id: user.id)
        article.communities << community
        article.update!(ai_agent_enabled: true, ai_agent_scope: 'community')
        article
      end

      it 'filters by ai_enabled parameter' do
        params = { ai_enabled: 'true' }
        records = portal_1.articles.search(params)
        expect(records).to include(ai_enabled_article, ai_group_article, ai_community_article)
        expect(records).not_to include(ai_disabled_article)

        params = { ai_enabled: 'false' }
        records = portal_1.articles.search(params)
        expect(records).to include(ai_disabled_article)
        expect(records).not_to include(ai_enabled_article, ai_group_article, ai_community_article)
      end

      it 'filters by ai_scope parameter' do
        params = { ai_scope: 'organization' }
        records = portal_1.articles.search(params)
        expect(records).to include(ai_enabled_article)
        expect(records).not_to include(ai_group_article, ai_community_article)

        params = { ai_scope: 'community_group' }
        records = portal_1.articles.search(params)
        expect(records).to include(ai_group_article)
        expect(records).not_to include(ai_enabled_article, ai_community_article)
      end

      it 'filters by community_group_ids parameter' do
        params = { community_group_ids: [community_group.id] }
        records = portal_1.articles.search(params)
        expect(records).to include(ai_group_article)
        expect(records).not_to include(ai_enabled_article, ai_community_article)
      end

      it 'filters by community_ids parameter' do
        params = { community_ids: [community.id] }
        records = portal_1.articles.search(params)
        expect(records).to include(ai_community_article)
        expect(records).not_to include(ai_enabled_article, ai_group_article)
      end

      it 'combines AI filters with other filters' do
        params = { ai_enabled: 'true', ai_scope: 'organization', locale: 'en' }
        records = portal_1.articles.search(params)
        expect(records).to include(ai_enabled_article)
        expect(records).not_to include(ai_group_article, ai_community_article, ai_disabled_article)
      end
    end

    describe 'ai_agent_scope_validations' do
      let(:article) { create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id) }
      let(:community_group) { create(:community_group, account: account) }
      let(:community) { create(:community, account: account) }

      it 'requires scope when AI agent is enabled' do
        article.ai_agent_enabled = true
        article.ai_agent_scope = nil
        expect(article).not_to be_valid
        expect(article.errors[:ai_agent_scope]).to include('must be selected when AI Agent is enabled')
      end

      it 'requires community_groups when scope is community_group' do
        article.ai_agent_enabled = true
        article.ai_agent_scope = 'community_group'
        expect(article).not_to be_valid
        expect(article.errors[:community_groups]).to include('must have at least one community group when scope is community_group')
      end

      it 'requires communities when scope is community' do
        article.ai_agent_enabled = true
        article.ai_agent_scope = 'community'
        expect(article).not_to be_valid
        expect(article.errors[:communities]).to include('must have at least one community when scope is community')
      end

      it 'is valid with proper community_group assignment' do
        article.community_groups << community_group
        article.ai_agent_enabled = true
        article.ai_agent_scope = 'community_group'
        expect(article).to be_valid
      end

      it 'is valid with proper community assignment' do
        article.communities << community
        article.ai_agent_enabled = true
        article.ai_agent_scope = 'community'
        expect(article).to be_valid
      end
    end
  end
end
