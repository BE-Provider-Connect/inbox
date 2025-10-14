class WebhookJob < ApplicationJob
  queue_as :medium
  #  There are 3 types of webhooks, account, inbox and agent_bot
  def perform(url, payload, webhook_type = :account_webhook)
    puts "[WebhookJob] Executing webhook to #{url} for message #{payload.dig(:message, :id) || 'N/A'}, event: #{payload[:event]}"
    Webhooks::Trigger.execute(url, payload, webhook_type)
  end
end
