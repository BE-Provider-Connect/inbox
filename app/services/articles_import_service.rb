# frozen_string_literal: true

require 'csv'
require 'open-uri'

class ArticlesImportService
  REQUIRED_HEADERS = %w[title content].freeze
  OPTIONAL_HEADERS = %w[description status category slug author_email].freeze

  attr_reader :sheet_url, :account_id, :imported_count, :errors

  def initialize(sheet_url:, account_id:)
    @sheet_url = sheet_url
    @account_id = account_id
    @imported_count = 0
    @errors = []
  end

  def perform
    validate_inputs!

    account = find_account!
    portal = find_or_create_portal(account)

    csv_content = fetch_csv_content

    import_articles(csv_content, account, portal)

    print_summary

    { success: errors.empty?, imported_count: imported_count, errors: errors }
  rescue StandardError => e
    handle_error(e)
  end

  private

  def validate_inputs!
    raise ArgumentError, 'Sheet URL is required' if sheet_url.blank?
    raise ArgumentError, 'Account ID is required' if account_id.blank?
    raise ArgumentError, 'Invalid URL format' unless valid_url?(sheet_url)
  end

  def valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def find_account!
    Account.find(account_id)
  rescue ActiveRecord::RecordNotFound
    raise ArgumentError, "Account with ID #{account_id} not found"
  end

  def find_or_create_portal(account)
    account.portals.first || create_default_portal(account)
  end

  def create_default_portal(account)
    Portal.create!(
      account: account,
      name: 'Knowledge Base',
      slug: 'knowledge-base',
      custom_domain: nil,
      color: '#1f93ff',
      config: {
        allowed_locales: ['en'],
        default_locale: 'en'
      }
    )
  end

  def fetch_csv_content
    puts "Fetching CSV from: #{sheet_url}"

    URI.open(sheet_url, read_timeout: 30).read
  rescue OpenURI::HTTPError => e
    raise StandardError, "Failed to fetch CSV: #{e.message}. Make sure the Google Sheet is published to web."
  rescue Net::ReadTimeout
    raise StandardError, 'Request timed out. Please check the URL and try again.'
  end

  def import_articles(csv_content, account, portal)
    csv = CSV.parse(csv_content, headers: true)

    validate_csv_headers!(csv.headers)

    csv.each_with_index do |row, index|
      import_single_article(row, account, portal, index + 2) # +2 for header row and 0-based index
    end
  end

  def validate_csv_headers!(headers)
    return if headers.nil?

    missing_headers = REQUIRED_HEADERS - headers.map(&:downcase)

    return if missing_headers.empty?

    raise ArgumentError, "Missing required headers: #{missing_headers.join(', ')}"
  end

  def import_single_article(row, account, portal, row_number)
    return if skip_row?(row)

    article_params = build_article_params(row, account, portal)

    article = Article.create!(article_params)

    @imported_count += 1
    puts "  ✓ Row #{row_number}: Created '#{article.title}'"
  rescue ActiveRecord::RecordInvalid => e
    error_msg = "Row #{row_number}: #{e.message}"
    @errors << error_msg
    puts "  ✗ #{error_msg}"
  rescue StandardError => e
    error_msg = "Row #{row_number}: Unexpected error - #{e.message}"
    @errors << error_msg
    puts "  ✗ #{error_msg}"
  end

  def skip_row?(row)
    row['title'].blank? && row['content'].blank?
  end

  def build_article_params(row, account, portal)
    category = find_or_create_category(portal, row['category'])
    author = find_author(account, row['author_email'])

    {
      account: account,
      portal: portal,
      category: category,
      author: author,
      title: row['title'].strip,
      content: row['content'],
      description: row['description'].presence || row['title'],
      slug: row['slug'].presence || generate_slug(row['title']),
      status: normalize_status(row['status']),
      position: row['position'].presence&.to_i || 0
    }.compact
  end

  def find_or_create_category(portal, category_name)
    name = category_name.presence || 'General'

    portal.categories.find_by(name: name) ||
      Category.create!(
        portal: portal,
        name: name,
        slug: generate_slug(name),
        locale: 'en',
        description: "#{name} articles"
      )
  end

  def find_author(account, author_email)
    return account.users.first if author_email.blank?

    account.users.find_by(email: author_email) || account.users.first
  end

  def generate_slug(text)
    text.downcase
        .strip
        .gsub(/[^\w\s-]/, '')
        .gsub(/[\s_-]+/, '-')
        .gsub(/^-|-$/, '')
  end

  def normalize_status(status)
    return 'published' if status.blank?

    valid_statuses = %w[draft published archived]
    status = status.downcase.strip

    valid_statuses.include?(status) ? status : 'published'
  end

  def print_summary
    puts "\n" + ('=' * 60)
    puts 'IMPORT SUMMARY'
    puts '=' * 60
    puts "✅ Successfully imported: #{imported_count} articles"

    if errors.any?
      puts "⚠️  Errors encountered: #{errors.size}"
      puts "\nError details:"
      errors.each { |error| puts "  - #{error}" }
    end

    puts '=' * 60
  end

  def handle_error(error)
    puts "\n❌ Import failed: #{error.message}"

    { success: false, imported_count: 0, errors: [error.message] }
  end
end
