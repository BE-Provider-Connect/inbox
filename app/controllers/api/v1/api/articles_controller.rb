class Api::V1::Api::ArticlesController < Api::BaseController
  include CitadelApiAuthHelper

  skip_before_action :authenticate_user!, :validate_bot_access_token!
  before_action :authenticate_citadel_api!

  respond_to :json

  def index
    @articles = Article
                .published
                .where(ai_agent_enabled: true)
                .includes(:communities, :community_groups, :account, :portal, :category, :author)

    # Apply filters
    @articles = @articles.where('articles.updated_at > ?', params[:updated_since]) if params[:updated_since].present?
    @articles = @articles.where(account_id: params[:account_ids]) if params[:account_ids].present?

    # Pagination
    @limit = params[:limit] || 100
    @offset = params[:offset] || 0
    @articles = @articles.limit(@limit).offset(@offset)

    # Get total count for pagination
    @total = @articles.except(:limit, :offset).count
    @has_more = @offset.to_i + @limit.to_i < @total
  end

  def show
    @article = Article.find_by(id: params[:id])

    render json: { error: 'Article not found' }, status: :not_found if @article.nil?
  end
end
