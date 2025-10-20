# frozen_string_literal: true

namespace :articles do
  desc 'Import articles from Google Sheets CSV URL'
  task :import, [:sheet_url, :account_id] => :environment do |_task, args|
    ArticlesImportService.new(
      sheet_url: args[:sheet_url],
      account_id: args[:account_id]
    ).perform
  end
end
