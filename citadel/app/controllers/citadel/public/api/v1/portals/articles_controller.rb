# frozen_string_literal: true

module Citadel::Public::Api::V1::Portals::ArticlesController
  def index
    @articles = @portal.articles.published.public_articles.includes(:category, :author)

    @articles = @articles.where(locale: permitted_params[:locale]) if permitted_params[:locale].present?

    @articles_count = @articles.count

    search_articles
    order_by_sort_param
    limit_results
  end

  def tracking_pixel
    @article = @portal.articles.public_articles.find_by(slug: permitted_params[:article_slug])
    return head :not_found unless @article

    @article.increment_view_count if @article.published?

    # Serve the 1x1 tracking pixel with 24-hour private cache
    # Private cache bypasses CDN but allows browser caching to prevent duplicate views from same user
    expires_in 24.hours, public: false
    response.headers['Content-Type'] = 'image/png'

    pixel_path = Rails.public_path.join('assets/images/tracking-pixel.png')
    send_file pixel_path, type: 'image/png', disposition: 'inline'
  end

  private

  def set_article
    @article = @portal.articles.published.public_articles.find_by(slug: permitted_params[:article_slug])
    return head :not_found unless @article

    @parsed_content = render_article_content(@article.content)
  end
end
