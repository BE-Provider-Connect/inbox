# frozen_string_literal: true

module Citadel::AssignmentHandler
  private

  def process_assignment_activities
    user_name = Current.user.name if Current.user.present?
    if saved_change_to_team_id?
      create_team_change_activity(user_name)
    elsif saved_change_to_assignee_id? || saved_change_to_assignee_type?
      # Also check assignee_type changes for polymorphic assignments
      # (e.g., changing from Assistant ID 1 to User ID 1)
      create_assignee_change_activity(user_name)
    end
  end
end
