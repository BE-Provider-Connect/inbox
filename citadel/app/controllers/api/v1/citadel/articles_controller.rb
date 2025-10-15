class Api::V1::Citadel::ArticlesController < Api::BaseController
  include CitadelApiAuthHelper

  skip_before_action :authenticate_user!, :validate_bot_access_token!
  before_action :authenticate_citadel_api!

  respond_to :json

  def index
    @articles = filtered_articles
    @limit = params[:limit] || 100
    @offset = params[:offset] || 0
    @articles = @articles.limit(@limit).offset(@offset)
    set_pagination_metadata
  end

  def show
    @article = Article.find_by(id: params[:id])

    render json: { error: 'Article not found' }, status: :not_found if @article.nil?
  end

  private

  def filtered_articles
    articles = base_articles_query
    articles = articles.where('articles.updated_at > ?', params[:updated_since]) if params[:updated_since].present?
    articles = articles.where(account_id: params[:account_ids]) if params[:account_ids].present?
    articles
  end

  def base_articles_query
    Article.published
           .where(ai_agent_enabled: true)
           .includes(:communities, :community_groups, :account, :portal, :category, :author)
  end

  def set_pagination_metadata
    @total = @articles.except(:limit, :offset).count
    @has_more = @offset.to_i + @limit.to_i < @total
  end
end
