require 'rails_helper'

RSpec.describe Article do
  let!(:account) { create(:account) }
  let(:user) { create(:user, account_ids: [account.id], role: :agent) }
  let!(:portal_1) { create(:portal, account_id: account.id, config: { allowed_locales: %w[en es] }) }
  let!(:category_1) { create(:category, slug: 'category_1', locale: 'en', portal_id: portal_1.id) }

  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:author_id) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:content) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:author) }
    it { is_expected.to have_many(:article_community_groups).dependent(:destroy) }
    it { is_expected.to have_many(:community_groups).through(:article_community_groups) }
    it { is_expected.to have_many(:article_communities).dependent(:destroy) }
    it { is_expected.to have_many(:communities).through(:article_communities) }
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
      articles = described_class.search_by_privacy('public')
      expect(articles).to include(public_article)
      expect(articles).not_to include(private_article)
    end

    it 'filters by private articles when privacy is private' do
      articles = described_class.search_by_privacy('private')
      expect(articles).to include(private_article)
      expect(articles).not_to include(public_article)
    end

    it 'returns all articles when privacy is nil or blank' do
      articles = described_class.search_by_privacy(nil)
      expect(articles).to include(public_article, private_article)

      articles = described_class.search_by_privacy('')
      expect(articles).to include(public_article, private_article)
    end
  end

  # This validation happens in ApplicationRecord
  describe 'length validations' do
    let(:article) do
      create(:article, category_id: category_1.id, content: 'This is the content', description: 'this is the description',
                       slug: 'this-is-title', title: 'this is title',
                       portal_id: portal_1.id, author_id: user.id)
    end

    context 'when it validates content length' do
      it 'valid when within limit' do
        article.content = 'a' * 1000
        expect(article.valid?).to be true
      end

      it 'invalid when crossed the limit' do
        article.content = 'a' * 25_001
        article.valid?
        expect(article.errors[:content]).to include('is too long (maximum is 20000 characters)')
      end
    end
  end

  describe 'add_locale_to_article' do
    let(:portal) { create(:portal, config: { allowed_locales: %w[en es pt], default_locale: 'es' }) }
    let(:category) { create(:category, slug: 'category_1', locale: 'pt', portal_id: portal.id) }

    it 'adds locale to article from category' do
      article = create(:article, category_id: category.id, content: 'This is the content', description: 'this is the description',
                                 slug: 'this-is-title', title: 'this is title',
                                 portal_id: portal.id, author_id: user.id)
      expect(article.locale).to eq(category.locale)
    end

    it 'adds locale to article from portal' do
      article = create(:article, content: 'This is the content', description: 'this is the description',
                                 slug: 'this-is-title', title: 'this is title',
                                 portal_id: portal.id, author_id: user.id, locale: '')
      expect(article.locale).to eq(portal.default_locale)
    end
  end

  describe 'search' do
    let!(:portal_2) { create(:portal, account_id: account.id, config: { allowed_locales: %w[en es] }) }
    let!(:category_2) { create(:category, slug: 'category_2', locale: 'es', portal_id: portal_1.id) }
    let!(:category_3) { create(:category, slug: 'category_3', locale: 'es', portal_id: portal_2.id) }

    before do
      create(:article, category_id: category_1.id, content: 'This is the content', description: 'this is the description',
                       slug: 'this-is-title', title: 'this is title',
                       portal_id: portal_1.id, author_id: user.id)
      create(:article, category_id: category_1.id, slug: 'title-1', title: 'title 1', content: 'This is the content', portal_id: portal_1.id,
                       author_id: user.id)
      create(:article, category_id: category_2.id, slug: 'title-2', title: 'title 2', portal_id: portal_2.id, author_id: user.id)
      create(:article, category_id: category_2.id, slug: 'title-3', title: 'title 3', portal_id: portal_1.id, author_id: user.id)
      create(:article, category_id: category_3.id, slug: 'title-6', title: 'title 6', portal_id: portal_2.id, author_id: user.id, status: :published)
      create(:article, category_id: category_2.id, slug: 'title-7', title: 'title 7', portal_id: portal_1.id, author_id: user.id, status: :published)
    end

    context 'when no parameters passed' do
      it 'returns all the articles in portal' do
        records = portal_1.articles.search({})
        expect(records.count).to eq(portal_1.articles.count)

        records = portal_2.articles.search({})
        expect(records.count).to eq(portal_2.articles.count)
      end
    end

    context 'when params passed' do
      it 'returns all the articles with all the params filters' do
        params = { query: 'title', locale: 'es', category_slug: 'category_3' }
        records = portal_2.articles.search(params)
        expect(records.count).to eq(1)

        params = { query: 'this', locale: 'en', category_slug: 'category_1' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)

        params = { status: 'published' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(portal_1.articles.published.size)
      end
    end

    context 'when some params missing' do
      it 'returns data with category slug' do
        params = { category_slug: 'category_2' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)
      end

      it 'returns data with locale' do
        params = { locale: 'es' }
        records = portal_2.articles.search(params)
        expect(records.count).to eq(2)

        params = { locale: 'en' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)
      end

      it 'returns data with text_search query' do
        params = { query: 'title' }
        records = portal_2.articles.search(params)

        expect(records.count).to eq(2)

        params = { query: 'title' }
        records = portal_1.articles.search(params)

        expect(records.count).to eq(4)

        params = { query: 'the content' }
        records = portal_1.articles.search(params)

        expect(records.count).to eq(2)
      end

      it 'returns data with text_search query and locale' do
        params = { query: 'title', locale: 'es' }
        records = portal_2.articles.search(params)
        expect(records.count).to eq(2)
      end

      it 'returns records with locale and category_slug' do
        params = { category_slug: 'category_2', locale: 'es' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)
      end

      it 'return records with category_slug and text_search query' do
        params = { category_slug: 'category_2', query: 'title' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)
      end

      it 'returns records with author and category_slug' do
        params = { category_slug: 'category_2', author_id: user.id }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)
      end

      it 'auto saves article slug' do
        article = create(:article, category_id: category_1.id, title: 'the awesome article 1', content: 'This is the content', portal_id: portal_1.id,
                                   author_id: user.id)
        expect(article.slug).to include('the-awesome-article-1')
      end
    end
  end

  describe '#to_llm_text' do
    it 'returns formatted article text' do
      category = create(:category, name: 'Test Category', slug: 'test_category', portal_id: portal_1.id)
      article = create(:article, title: 'Test Article', category_id: category.id, content: 'This is the content', portal_id: portal_1.id,
                                 author_id: user.id)
      expected_output = <<~TEXT
        Title: #{article.title}
        ID: #{article.id}
        Status: #{article.status}
        Category: #{category.name}
        Author: #{user.name}
        Views: #{article.views}
        Created At: #{article.created_at}
        Updated At: #{article.updated_at}
        Content:
        #{article.content}
      TEXT

      expect(article.to_llm_text).to eq(expected_output)
    end
  end

  describe 'AI agent functionality' do
    let(:article) { create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id) }
    let!(:community_group) { create(:community_group) }
    let!(:community) { create(:community, community_group: community_group) }

    describe 'ai_agent_enabled field' do
      it 'defaults to false' do
        expect(article.ai_agent_enabled).to be false
      end
    end

    describe 'many-to-many associations' do
      it 'can belong to multiple community groups' do
        groups = create_list(:community_group, 3)
        article.community_groups = groups
        expect(article.community_groups.count).to eq(3)
      end

      it 'can belong to multiple communities' do
        communities = create_list(:community, 3)
        article.communities = communities
        expect(article.communities.count).to eq(3)
      end
    end

    describe 'ai_agent_scope validation' do
      it 'is valid with organization scope and no entities' do
        article.update(ai_agent_enabled: true, ai_agent_scope: 'organization')
        expect(article).to be_valid
      end

      it 'is invalid with community_group scope and no groups' do
        article.ai_agent_enabled = true
        article.ai_agent_scope = 'community_group'
        expect(article).not_to be_valid
        expect(article.errors[:community_groups]).to include('must have at least one community group when scope is community_group')
      end

      it 'is valid with community_group scope and groups assigned' do
        article.ai_agent_enabled = true
        article.ai_agent_scope = 'community_group'
        article.community_groups << community_group
        expect(article).to be_valid
      end

      it 'is invalid with community scope and no communities' do
        article.ai_agent_enabled = true
        article.ai_agent_scope = 'community'
        expect(article).not_to be_valid
        expect(article.errors[:communities]).to include('must have at least one community when scope is community')
      end

      it 'is valid with community scope and communities assigned' do
        article.ai_agent_enabled = true
        article.ai_agent_scope = 'community'
        article.communities << community
        expect(article).to be_valid
      end
    end

    describe 'scopes' do
      let!(:ai_article) do
        create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id, ai_agent_enabled: true,
                         ai_agent_scope: 'organization')
      end
      let!(:regular_article) { create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id, ai_agent_enabled: false) }

      it 'filters by ai_enabled' do
        articles = described_class.ai_enabled
        expect(articles).to include(ai_article)
        expect(articles).not_to include(regular_article)
      end

      it 'filters by ai_agent_scope' do
        group_article = create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id)
        group_article.community_groups << community_group
        group_article.update!(ai_agent_enabled: true, ai_agent_scope: 'community_group')

        articles = described_class.by_ai_scope('community_group')
        expect(articles).to include(group_article)
        expect(articles).not_to include(ai_article)
      end

      it 'filters by community_group' do
        group_article = create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id)
        group_article.community_groups << community_group

        articles = described_class.for_community_group(community_group.id)
        expect(articles).to include(group_article)
        expect(articles).not_to include(ai_article)
      end

      it 'filters by community' do
        community_article = create(:article, portal_id: portal_1.id, category_id: category_1.id, author_id: user.id)
        community_article.communities << community

        articles = described_class.for_community(community.id)
        expect(articles).to include(community_article)
        expect(articles).not_to include(ai_article)
      end
    end
  end
end
