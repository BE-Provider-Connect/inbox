# frozen_string_literal: true

module Citadel::Article::Search
  def search(params)
    records = left_outer_joins(
      :category
    ).search_by_category_slug(
      params[:category_slug]
    ).search_by_locale(params[:locale]).search_by_author(params[:author_id]).search_by_status(params[:status])
              .search_by_privacy(params[:privacy])
              .search_by_ai_enabled(params[:ai_enabled])
              .search_by_ai_scope(params[:ai_scope])
              .search_by_community_groups(params[:community_group_ids])
              .search_by_communities(params[:community_ids])

    records = records.text_search(params[:query]) if params[:query].present?
    records
  end
end
