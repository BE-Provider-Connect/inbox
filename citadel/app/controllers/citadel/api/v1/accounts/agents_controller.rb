# frozen_string_literal: true

module Citadel::Api::V1::Accounts::AgentsController
  def index
    super
    # Include the Assistant singleton in the agents list
    @assistant = Assistant.instance if Assistant.instance.enabled?
  end
end
