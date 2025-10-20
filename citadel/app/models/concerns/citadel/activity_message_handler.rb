module Citadel::ActivityMessageHandler
  def generate_assignee_change_activity_content(user_name)
    assignee_name = if assignee_type == 'Assistant'
                      Assistant.find_by(id: assignee_id)&.name || ''
                    elsif assignee_type == 'User'
                      User.find_by(id: assignee_id)&.name || ''
                    else
                      assignee&.name || ''
                    end

    params = { assignee_name: assignee_name, user_name: user_name }
    key = assignee_id ? 'assigned' : 'removed'
    key = 'self_assigned' if assignee_type == 'User' && self_assign?(assignee_id)
    I18n.t("conversations.activity.assignee.#{key}", **params)
  end
end
