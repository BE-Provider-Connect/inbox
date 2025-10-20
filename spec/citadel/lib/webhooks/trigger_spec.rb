require 'rails_helper'

RSpec.describe Webhooks::Trigger do
  subject(:trigger) { described_class }

  let(:webhook_type) { :assistant_webhook }
  let(:url) { 'http://localhost:3333/v1/webhooks/chatwoot' }
  let(:payload) { { event: 'message_created', content: 'test' } }

  before do
    stub_const('ENV', ENV.to_hash.merge(
                        'CITADEL_API_WEBHOOK_URL' => 'http://localhost:3333/v1/webhooks/chatwoot',
                        'CITADEL_API_KEY' => 'test-api-key-123'
                      ))
  end

  describe 'Citadel assistant webhook extension' do
    it 'adds X-Api-Key header for assistant webhooks to Citadel API' do
      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: hash_including('X-Api-Key' => 'test-api-key-123'),
          timeout: 5
        ).once

      trigger.execute(url, payload, webhook_type)
    end

    it 'does not add X-Api-Key header when URL does not match CITADEL_API_WEBHOOK_URL' do
      other_url = 'https://other-service.com/webhook'

      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: other_url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: 5
        ).once

      trigger.execute(other_url, payload, webhook_type)
    end

    it 'does not add X-Api-Key header for non-assistant webhook types' do
      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: 5
        ).once

      trigger.execute(url, payload, :account_webhook)
    end
  end
end
