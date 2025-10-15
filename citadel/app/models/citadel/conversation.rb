# frozen_string_literal: true

module Citadel::Conversation
  extend ActiveSupport::Concern

  included do
    # Override the assignee association to make it polymorphic (User or Assistant)
    belongs_to :assignee, polymorphic: true, optional: true

    # Update scope to handle polymorphic assignee
    scope :assigned_to, ->(agent) { where(assignee_id: agent.id, assignee_type: agent.class.name) }
  end

  # Override notifiable_assignee_change? to handle Assistant assignees
  def notifiable_assignee_change?
    return false unless saved_change_to_assignee_id?
    return false if assignee_id.blank?
    return false if assignee_type == 'User' && self_assign?(assignee_id)

    true
  end
end
