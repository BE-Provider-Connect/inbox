# frozen_string_literal: true

module Citadel::Api::V1::Accounts::BulkActionsController
  private

  def permitted_params
    params.permit(:type, :snoozed_until, ids: [], fields: [:status, :assignee_id, :assignee_type, :team_id], labels: [add: [], remove: []])
  end
end
