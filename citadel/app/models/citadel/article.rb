# frozen_string_literal: true

module Citadel::Article
  extend ActiveSupport::Concern

  included do
    # AI Agent associations
    has_many :article_community_groups, dependent: :destroy
    has_many :community_groups, through: :article_community_groups

    has_many :article_communities, dependent: :destroy
    has_many :communities, through: :article_communities

    # AI Agent validations
    validate :validate_ai_agent_scope_entities

    # AI Agent scope enum
    enum ai_agent_scope: { organization: 0, community_group: 1, community: 2 }

    # Privacy scopes
    scope :search_by_privacy, lambda { |privacy|
      return all if privacy.blank?

      privacy == 'private' ? where(private: true) : where(private: false)
    }
    scope :public_articles, -> { where(private: false) }

    # AI Agent scopes
    scope :search_by_ai_enabled, lambda { |ai_enabled|
      return all if ai_enabled.blank?

      ai_enabled == 'true' ? where(ai_agent_enabled: true) : where(ai_agent_enabled: false)
    }
    scope :search_by_ai_scope, ->(ai_scope) { where(ai_agent_scope: ai_scope) if ai_scope.present? }
    scope :search_by_community_groups, lambda { |group_ids|
      return all if group_ids.blank?

      joins(:article_community_groups)
        .where(article_community_groups: { community_group_id: group_ids })
        .distinct
    }
    scope :search_by_communities, lambda { |community_ids|
      return all if community_ids.blank?

      joins(:article_communities)
        .where(article_communities: { community_id: community_ids })
        .distinct
    }
  end

  private

  def validate_ai_agent_scope_entities
    return unless ai_agent_enabled

    # If AI Agent is enabled, scope must be present
    if ai_agent_scope.blank?
      errors.add(:ai_agent_scope, 'must be selected when AI Agent is enabled')
      return
    end

    case ai_agent_scope
    when 'community_group'
      errors.add(:community_groups, 'must have at least one community group when scope is community_group') if community_group_ids.blank?
    when 'community'
      errors.add(:communities, 'must have at least one community when scope is community') if community_ids.blank?
    end
  end
end
