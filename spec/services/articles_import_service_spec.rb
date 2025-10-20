# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArticlesImportService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:sheet_url) { 'https://docs.google.com/spreadsheets/d/e/test/pub?output=csv' }

  let(:valid_csv_content) do
    <<~CSV
      title,content,description,status,category,author_email
      "Getting Started","This is the getting started guide","A beginner's guide","published","Documentation","#{user.email}"
      "Advanced Features","Learn about advanced features","Advanced user guide","draft","Tutorials",""
      "FAQ","Frequently asked questions","Common questions","published","Support",""
    CSV
  end

  let(:csv_with_missing_headers) do
    <<~CSV
      description,status
      "A guide","published"
    CSV
  end

  let(:csv_with_empty_rows) do
    <<~CSV
      title,content,description
      "Article 1","Content 1","Description 1"
      ,,
      "Article 2","Content 2","Description 2"
    CSV
  end

  let(:csv_with_invalid_data) do
    <<~CSV
      title,content,description
      "","No title article","This should fail"
      "Valid Article","Valid content","Valid description"
    CSV
  end

  describe '#initialize' do
    it 'initializes with required parameters' do
      service = described_class.new(sheet_url: sheet_url, account_id: account.id)

      expect(service.sheet_url).to eq(sheet_url)
      expect(service.account_id).to eq(account.id)
      expect(service.imported_count).to eq(0)
      expect(service.errors).to eq([])
    end

    it 'raises error if account_id is not provided' do
      expect do
        described_class.new(sheet_url: sheet_url)
      end.to raise_error(ArgumentError, /account_id/)
    end
  end

  describe '#perform' do
    let(:service) { described_class.new(sheet_url: sheet_url, account_id: account.id) }

    before do
      allow(service).to receive(:fetch_csv_content).and_return(valid_csv_content)
    end

    context 'with valid CSV data' do
      it 'creates articles successfully' do
        expect { service.perform }.to change(Article, :count).by(3)
      end

      it 'creates portal if none exists' do
        expect(account.portals.count).to eq(0)

        service.perform

        expect(account.portals.count).to eq(1)
        expect(account.portals.first.name).to eq('Knowledge Base')
      end

      it 'uses existing portal if available' do
        existing_portal = create(:portal, account: account, name: 'Existing Portal')

        service.perform
        articles = Article.where(portal: existing_portal)

        expect(articles.count).to eq(3)
      end

      it 'creates categories from CSV data' do
        service.perform

        categories = Category.pluck(:name)
        expect(categories).to include('Documentation', 'Tutorials', 'Support')
      end

      it 'assigns correct author based on email' do
        service.perform

        article = Article.find_by(title: 'Getting Started')
        expect(article.author).to eq(user)
      end

      it 'uses first account user when author_email is blank' do
        service.perform

        article = Article.find_by(title: 'FAQ')
        expect(article.author).to eq(account.users.first)
      end

      it 'returns success result' do
        result = service.perform

        expect(result[:success]).to be true
        expect(result[:imported_count]).to eq(3)
        expect(result[:errors]).to be_empty
      end

      it 'sets correct article attributes' do
        service.perform

        article = Article.find_by(title: 'Getting Started')
        expect(article.content).to eq('This is the getting started guide')
        expect(article.description).to eq("A beginner's guide")
        expect(article.status).to eq('published')
      end

      it 'generates slug from title when not provided' do
        service.perform

        article = Article.find_by(title: 'Getting Started')
        expect(article.slug).to match(/getting-started/)
      end
    end

    context 'with missing required headers' do
      before do
        allow(service).to receive(:fetch_csv_content).and_return(csv_with_missing_headers)
      end

      it 'raises an error about missing headers' do
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:errors].first).to include('Missing required headers')
      end

      it 'does not create any articles' do
        expect { service.perform }.not_to change(Article, :count)
      end
    end

    context 'with empty rows' do
      before do
        allow(service).to receive(:fetch_csv_content).and_return(csv_with_empty_rows)
      end

      it 'skips empty rows' do
        expect { service.perform }.to change(Article, :count).by(2)
      end

      it 'reports correct import count' do
        result = service.perform

        expect(result[:imported_count]).to eq(2)
      end
    end

    context 'with invalid data' do
      before do
        allow(service).to receive(:fetch_csv_content).and_return(csv_with_invalid_data)
      end

      it 'creates valid articles and logs errors for invalid ones' do
        expect { service.perform }.to change(Article, :count).by(1)
      end

      it 'collects errors for invalid rows' do
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:errors]).not_to be_empty
        expect(result[:errors].first).to include('Row 2')
      end

      it 'continues processing after encountering errors' do
        service.perform

        expect(Article.find_by(title: 'Valid Article')).to be_present
      end
    end

    context 'with invalid URL' do
      let(:invalid_service) { described_class.new(sheet_url: 'not-a-url', account_id: account.id) }

      it 'returns error for invalid URL format' do
        result = invalid_service.perform

        expect(result[:success]).to be false
        expect(result[:errors].first).to include('Invalid URL format')
      end
    end

    context 'with missing account_id' do
      it 'returns error for missing account_id' do
        service = described_class.new(sheet_url: sheet_url, account_id: nil)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:errors].first).to include('Account ID is required')
      end
    end

    context 'with non-existent account' do
      let(:invalid_service) { described_class.new(sheet_url: sheet_url, account_id: 999_999) }

      it 'returns error for missing account' do
        result = invalid_service.perform

        expect(result[:success]).to be false
        expect(result[:errors].first).to include('Account with ID 999999 not found')
      end
    end

    context 'with network errors' do
      before do
        allow(service).to receive(:fetch_csv_content).and_raise(
          OpenURI::HTTPError.new('404 Not Found', StringIO.new)
        )
      end

      it 'handles HTTP errors gracefully' do
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:errors].first).to include('404 Not Found')
      end
    end

    context 'with timeout' do
      before do
        allow(service).to receive(:fetch_csv_content).and_raise(Net::ReadTimeout)
      end

      it 'handles timeout errors' do
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:errors].first).to include('ReadTimeout')
      end
    end

    context 'with status normalization' do
      let(:csv_with_various_statuses) do
        <<~CSV
          title,content,status
          "Article 1","Content 1","PUBLISHED"
          "Article 2","Content 2","Draft"
          "Article 3","Content 3","invalid_status"
          "Article 4","Content 4",""
        CSV
      end

      before do
        allow(service).to receive(:fetch_csv_content).and_return(csv_with_various_statuses)
      end

      it 'normalizes status values correctly' do
        service.perform

        expect(Article.find_by(title: 'Article 1').status).to eq('published')
        expect(Article.find_by(title: 'Article 2').status).to eq('draft')
        expect(Article.find_by(title: 'Article 3').status).to eq('published') # defaults to published
        expect(Article.find_by(title: 'Article 4').status).to eq('published') # defaults to published
      end
    end

    context 'with special characters in titles' do
      let(:csv_with_special_chars) do
        <<~CSV
          title,content
          "Article with émojis! 🎉 & symbols #$%","Content here"
          "Article with/slashes\\and|pipes","More content"
        CSV
      end

      before do
        allow(service).to receive(:fetch_csv_content).and_return(csv_with_special_chars)
      end

      it 'creates articles with special characters in titles' do
        expect { service.perform }.to change(Article, :count).by(2)
      end

      it 'generates clean slugs from titles with special characters' do
        service.perform

        article1 = Article.find_by(title: "Article with émojis! 🎉 & symbols \#$%")
        expect(article1.slug).to match(/article-with-mojis-symbols/)

        article2 = Article.find_by(title: 'Article with/slashes\\and|pipes')
        expect(article2.slug).to match(/article-withslashesandpipes/)
      end
    end
  end

  describe 'rake task integration' do
    before do
      Rails.application.load_tasks
      Rake::Task['articles:import'].reenable if Rake::Task.task_defined?('articles:import')
    end

    it 'calls ArticlesImportService with correct parameters' do
      expect_any_instance_of(ArticlesImportService).to receive(:perform)

      Rake::Task['articles:import'].invoke(sheet_url, account.id.to_s)
    end
  end
end
