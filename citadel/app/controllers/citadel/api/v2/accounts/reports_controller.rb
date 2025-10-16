# frozen_string_literal: true

module Citadel::Api::V2::Accounts::ReportsController
  extend ActiveSupport::Concern

  included do
    include Citadel::Api::V2::Accounts::ReportsHelper
  end
end
