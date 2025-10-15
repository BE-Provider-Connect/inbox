# frozen_string_literal: true

module Citadel::Api::V1::Accounts::ArticlesController
  def update
    ActiveRecord::Base.transaction do
      clear_ai_agent_associations_on_scope_change
      super
    end
  end

  private

  def article_params
    super.merge(
      params.require(:article).permit(
        :private, :ai_agent_enabled, :ai_agent_scope,
        community_group_ids: [],
        community_ids: []
      )
    )
  end

  def list_params
    super.merge(
      params.permit(
        :privacy, :ai_enabled, :ai_scope,
        community_group_ids: [],
        community_ids: []
      )
    )
  end

  def clear_ai_agent_associations_on_scope_change
    return if params.dig(:article, :ai_agent_scope).blank?

    case params[:article][:ai_agent_scope]
    when 'organization'
      @article.community_groups.clear
      @article.communities.clear
    when 'community_group'
      @article.communities.clear
    when 'community'
      @article.community_groups.clear
    end
  end
end
