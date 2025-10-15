# frozen_string_literal: true

module Citadel::Api::V1::Accounts::AssignableAgentsController
  def index
    super
    # Add AI Assistant to assignable agents list
    assistant = Assistant.instance
    @assignable_agents << assistant if assistant.enabled?
  end
end
