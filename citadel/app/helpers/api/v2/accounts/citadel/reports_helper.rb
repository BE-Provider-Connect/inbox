# frozen_string_literal: true

module Citadel::Api::V2::Accounts::ReportsHelper
  def generate_agents_report
    reports = V2::Reports::AgentSummaryBuilder.new(
      account: Current.account,
      params: build_params(type: :agent)
    ).build

    # Include both users and assistant in the CSV export
    agents = Current.account.users.to_a

    assistant = Assistant.instance
    agents << assistant if assistant&.enabled?

    agents.map do |agent|
      report = reports.find { |r| r[:id] == agent.id }
      [agent.name] + generate_readable_report_metrics(report)
    end
  end
end
