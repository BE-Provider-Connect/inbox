# frozen_string_literal: true

module Citadel::Account
  extend ActiveSupport::Concern

  included do
    # Citadel associations
    has_many :communities, dependent: :destroy_async
    has_many :community_groups, dependent: :destroy_async

    # External ID for syncing with external systems
    validates :external_id, uniqueness: true, allow_nil: true
  end
end
