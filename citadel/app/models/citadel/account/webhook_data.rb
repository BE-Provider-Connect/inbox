# frozen_string_literal: true

module Citadel::Account::WebhookData
  # Override webhook_data to include external_id
  def webhook_data
    {
      id: id,
      name: name,
      external_id: external_id
    }
  end
end
