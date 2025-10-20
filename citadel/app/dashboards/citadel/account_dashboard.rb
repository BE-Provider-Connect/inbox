# frozen_string_literal: true

# Reopen AccountDashboard to add external_id field support
AccountDashboard.class_eval do
  # Remove the old constants
  remove_const :ATTRIBUTE_TYPES
  remove_const :COLLECTION_ATTRIBUTES
  remove_const :SHOW_PAGE_ATTRIBUTES
  remove_const :FORM_ATTRIBUTES

  # Redefine with external_id
  enterprise_attribute_types = if ChatwootApp.enterprise?
                                 attributes = {
                                   limits: AccountLimitsField
                                 }

                                 attributes[:manually_managed_features] = ManuallyManagedFeaturesField if ChatwootApp.chatwoot_cloud?
                                 attributes[:all_features] = AccountFeaturesField

                                 attributes
                               else
                                 {}
                               end

  ATTRIBUTE_TYPES = {
    id: Field::Number.with_options(searchable: true),
    name: Field::String.with_options(searchable: true),
    external_id: Field::String.with_options(searchable: true),
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    users: CountField,
    conversations: CountField,
    locale: Field::Select.with_options(collection: LANGUAGES_CONFIG.map { |_x, y| y[:iso_639_1_code] }),
    status: Field::Select.with_options(collection: [%w[Active active], %w[Suspended suspended]]),
    account_users: Field::HasMany,
    custom_attributes: Field::String
  }.merge(enterprise_attribute_types).freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    external_id
    locale
    users
    conversations
    status
  ].freeze

  enterprise_show_page_attributes = if ChatwootApp.enterprise?
                                      attrs = %i[custom_attributes limits]
                                      attrs << :manually_managed_features if ChatwootApp.chatwoot_cloud?
                                      attrs << :all_features
                                      attrs
                                    else
                                      []
                                    end

  SHOW_PAGE_ATTRIBUTES = (%i[
    id
    name
    external_id
    created_at
    updated_at
    locale
    status
    conversations
    account_users
  ] + enterprise_show_page_attributes).freeze

  enterprise_form_attributes = if ChatwootApp.enterprise?
                                 attrs = %i[limits]
                                 attrs << :manually_managed_features if ChatwootApp.chatwoot_cloud?
                                 attrs << :all_features
                                 attrs
                               else
                                 []
                               end

  FORM_ATTRIBUTES = (%i[
    name
    external_id
    locale
    status
  ] + enterprise_form_attributes).freeze
end
