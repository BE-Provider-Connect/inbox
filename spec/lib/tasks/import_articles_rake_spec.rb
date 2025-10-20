# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'articles:import rake task' do
  let(:account) { create(:account) }
  let(:sheet_url) { 'https://docs.google.com/spreadsheets/d/test/pub?output=csv' }

  before do
    # Load the rake task
    Rake.application.rake_require 'tasks/import_articles'

    # Ensure environment task exists (required by our task)
    Rake::Task.define_task(:environment)

    # Allow task to be run multiple times in tests
    Rake::Task['articles:import'].reenable
  end

  describe 'articles:import' do
    let(:task) { Rake::Task['articles:import'] }

    it 'is defined' do
      expect(task).to be_present
    end

    it 'accepts sheet_url and account_id as arguments' do
      expect(task.arg_names).to include(:sheet_url, :account_id)
    end

    context 'when invoked' do
      let(:service_double) { instance_double(ArticlesImportService) }

      before do
        allow(ArticlesImportService).to receive(:new).and_return(service_double)
        allow(service_double).to receive(:perform).and_return(
          { success: true, imported_count: 5, errors: [] }
        )
      end

      it 'creates ArticlesImportService with provided arguments' do
        expect(ArticlesImportService).to receive(:new).with(
          sheet_url: sheet_url,
          account_id: account.id.to_s
        )

        task.invoke(sheet_url, account.id.to_s)
      end

      it 'calls perform on the service instance' do
        expect(service_double).to receive(:perform)

        task.invoke(sheet_url, account.id.to_s)
      end

      it 'requires account_id to be provided' do
        expect(ArticlesImportService).to receive(:new).with(
          sheet_url: sheet_url,
          account_id: nil
        ).and_return(service_double)

        task.invoke(sheet_url, nil)
      end
    end

    context 'with real service integration' do
      let(:user) { create(:user, account: account) }
      let(:csv_content) do
        <<~CSV
          title,content,description,author_email
          "Test Article","Test content","Test description","#{user.email}"
        CSV
      end

      before do
        user # Ensure user is created
        allow_any_instance_of(ArticlesImportService).to receive(:fetch_csv_content).and_return(csv_content)
      end

      it 'successfully imports articles' do
        expect { task.invoke(sheet_url, account.id.to_s) }.to change(Article, :count).by(1)

        article = Article.last
        expect(article.title).to eq('Test Article')
        expect(article.content).to eq('Test content')
      end

      it 'outputs progress to console' do
        expect { task.invoke(sheet_url, account.id.to_s) }.to output(/Successfully imported: 1 articles/).to_stdout
      end
    end

    context 'error handling' do
      it 'handles missing sheet_url gracefully' do
        expect { task.invoke(nil, account.id.to_s) }.to output(/Sheet URL is required/).to_stdout
      end

      it 'handles missing account_id gracefully' do
        expect { task.invoke(sheet_url, nil) }.to output(/Account ID is required/).to_stdout
      end

      it 'handles invalid URLs gracefully' do
        expect { task.invoke('not-a-url', account.id.to_s) }.to output(/Invalid URL format/).to_stdout
      end

      it 'handles non-existent accounts' do
        expect { task.invoke(sheet_url, '999999') }.to output(/Account with ID 999999 not found/).to_stdout
      end
    end
  end
end
