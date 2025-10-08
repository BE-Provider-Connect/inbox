class Api::V1::Sync::ArticlesController < Api::BaseController
  skip_before_action :authenticate_user!, :authenticate_access_token!, :validate_bot_access_token!
  before_action :authenticate_citadel

  def index
    articles = Article
               .published
               .where(ai_agent_enabled: true)
               .includes(:communities, :community_groups, :account, :portal, :category, :author)

    # Apply filters
    articles = articles.where('articles.updated_at > ?', params[:updated_since]) if params[:updated_since].present?
    articles = articles.where(account_id: params[:account_ids]) if params[:account_ids].present?

    # Pagination
    limit = params[:limit] || 100
    offset = params[:offset] || 0
    articles = articles.limit(limit).offset(offset)

    # Get total count for pagination
    total = articles.except(:limit, :offset).count

    render json: {
      articles: format_articles(articles),
      meta: {
        total: total,
        limit: limit.to_i,
        offset: offset.to_i,
        has_more: offset.to_i + limit.to_i < total
      }
    }
  end

  def show
    article = Article.find_by(id: params[:id])

    if article
      render json: {
        article: format_article(article)
      }
    else
      render json: { error: 'Article not found' }, status: :not_found
    end
  end

  private

  def authenticate_citadel
    api_key = request.headers['X-API-Key'] ||
              request.headers['Authorization']&.gsub('Bearer ', '')

    return if api_key.present? && api_key == ENV['CITADEL_API_KEY']

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def format_articles(articles)
    articles.map { |article| format_article(article) }
  end

  def format_article(article)
    {
      id: article.id,
      account_id: article.account_id,
      account_external_id: article.account.external_id,
      portal_id: article.portal_id,
      category_id: article.category_id,
      title: article.title,
      content: article.content,
      description: article.description,
      slug: article.slug,
      status: article.status,
      locale: article.locale,
      position: article.position,
      views: article.views,
      ai_agent_enabled: article.ai_agent_enabled,
      ai_agent_scope: article.ai_agent_scope,
      created_at: article.created_at,
      updated_at: article.updated_at,
      author: {
        id: article.author_id,
        name: article.author&.name,
        email: article.author&.email
      },
      portal: {
        id: article.portal&.id,
        name: article.portal&.name,
        slug: article.portal&.slug
      },
      category: if article.category
                  {
                    id: article.category.id,
                    name: article.category.name,
                    slug: article.category.slug
                  }
                end,
      community_groups: article.community_groups.map do |group|
        {
          id: group.id,
          external_id: group.external_id,
          name: group.name,
          account_id: group.account_id
        }
      end,
      communities: article.communities.map do |community|
        {
          id: community.id,
          external_id: community.external_id,
          name: community.name,
          account_id: community.account_id,
          community_group_id: community.community_group_id
        }
      end
    }
  end
end
