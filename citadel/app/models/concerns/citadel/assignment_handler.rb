# frozen_string_literal: true

module Citadel::AssignmentHandler
  include Events::Types

  private

  def notify_assignment_change
    {
      ASSIGNEE_CHANGED => -> { saved_change_to_assignee_id? || saved_change_to_assignee_type? },
      TEAM_CHANGED => -> { saved_change_to_team_id? }
    }.each do |event, condition|
      dispatcher_dispatch(event, previous_changes) if condition.call
    end
  end

  def process_assignment_activities
    user_name = Current.user.name if Current.user.present?

    if saved_change_to_team_id?
      create_team_change_activity(user_name)
    elsif saved_change_to_assignee_id? || saved_change_to_assignee_type?
      create_assignee_change_activity(user_name)
    end
  end
end
