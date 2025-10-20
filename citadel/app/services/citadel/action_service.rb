# frozen_string_literal: true

module Citadel::ActionService
  def assign_agent(agent_ids = [])
    return @conversation.update!(assignee: nil) if agent_ids[0] == 'nil'

    agent_id = agent_ids[0]

    # Try to find as Assistant first (if ID format is "assistant_1")
    if agent_id.to_s.start_with?('assistant_')
      assistant_id = agent_id.to_s.sub('assistant_', '').to_i
      assistant = Assistant.find_by(id: assistant_id)
      return @conversation.update!(assignee: assistant) if assistant.present?
    end

    # Try to find as User
    return unless agent_belongs_to_inbox?(agent_ids)

    @agent = @account.users.find_by(id: agent_id)
    @conversation.update!(assignee: @agent) if @agent.present?
  end
end
