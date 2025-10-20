# frozen_string_literal: true

# Load Citadel extensions after the application initializes
Rails.application.config.after_initialize do
  # Load dashboard extensions
  require_relative '../../citadel/app/dashboards/extensions/account_dashboard_extension' if defined?(AccountDashboard) && ChatwootApp.citadel?
end
