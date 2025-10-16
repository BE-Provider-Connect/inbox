# frozen_string_literal: true

module Citadel::Conversation
  extend ActiveSupport::Concern

  included do
    # Override the assignee association to make it polymorphic (User or Assistant)
    belongs_to :assignee, polymorphic: true, optional: true

    # Normalize assignee_type: 'Assistant' for Assistant, 'User' for everything else
    before_save :normalize_assignee_type

    # Update scope to handle polymorphic assignee
    scope :assigned_to, ->(agent) { where(assignee_id: agent.id, assignee_type: agent.is_a?(Assistant) ? 'Assistant' : 'User') }
  end

  # Override notifiable_assignee_change? to handle Assistant assignees
  def notifiable_assignee_change?
    return false unless saved_change_to_assignee_id?
    return false if assignee_id.blank?
    return false if assignee_type == 'User' && self_assign?(assignee_id)

    true
  end

  private

  def normalize_assignee_type
    # If it's an Assistant -> 'Assistant', else -> 'User'
    # This handles User, SuperAdmin, and any other User subclasses as 'User'
    if assignee.is_a?(Assistant)
      self.assignee_type = 'Assistant'
    elsif assignee.present?
      self.assignee_type = 'User'
    end
  end
end
