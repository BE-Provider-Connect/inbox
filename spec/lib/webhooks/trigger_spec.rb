require 'rails_helper'

describe Webhooks::Trigger do
  subject(:trigger) { described_class }

  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, inbox: inbox) }
  let!(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }

  let!(:webhook_type) { :api_inbox_webhook }
  let!(:url) { 'https://test.com' }

  describe '#execute' do
    it 'triggers webhook' do
      payload = { hello: :hello }

      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: 5
        ).once
      trigger.execute(url, payload, webhook_type)
    end

    context 'with ENV placeholder URLs' do
      it 'resolves ENV variable when URL starts with ENV:' do
        ENV['TEST_WEBHOOK_URL'] = 'https://resolved.webhook.com'
        payload = { test: :data }

        expect(RestClient::Request).to receive(:execute)
          .with(
            method: :post,
            url: 'https://resolved.webhook.com',
            payload: payload.to_json,
            headers: { content_type: :json, accept: :json },
            timeout: 5
          ).once

        trigger.execute('ENV:TEST_WEBHOOK_URL', payload, webhook_type)

        ENV['TEST_WEBHOOK_URL'] = nil
      end

      it 'raises error when ENV variable is missing' do
        payload = { test: :data }

        expect { trigger.execute('ENV:MISSING_VAR', payload, webhook_type) }
          .to raise_error(RuntimeError, 'Missing ENV variable: MISSING_VAR')
      end

      it 'raises error when ENV variable is blank' do
        ENV['EMPTY_VAR'] = ''
        payload = { test: :data }

        expect { trigger.execute('ENV:EMPTY_VAR', payload, webhook_type) }
          .to raise_error(RuntimeError, 'Missing ENV variable: EMPTY_VAR')

        ENV['EMPTY_VAR'] = nil
      end

      it 'uses normal URL when not an ENV placeholder' do
        payload = { test: :data }

        expect(RestClient::Request).to receive(:execute)
          .with(
            method: :post,
            url: 'https://normal.webhook.com',
            payload: payload.to_json,
            headers: { content_type: :json, accept: :json },
            timeout: 5
          ).once

        trigger.execute('https://normal.webhook.com', payload, webhook_type)
      end
    end

    it 'updates message status if webhook fails for message-created event' do
      payload = { event: 'message_created', conversation: { id: conversation.id }, id: message.id }

      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: 5
        ).and_raise(RestClient::ExceptionWithResponse.new('error', 500)).once

      expect { trigger.execute(url, payload, webhook_type) }.to change { message.reload.status }.from('sent').to('failed')
    end

    it 'updates message status if webhook fails for message-updated event' do
      payload = { event: 'message_updated', conversation: { id: conversation.id }, id: message.id }

      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: 5
        ).and_raise(RestClient::ExceptionWithResponse.new('error', 500)).once
      expect { trigger.execute(url, payload, webhook_type) }.to change { message.reload.status }.from('sent').to('failed')
    end
  end

  it 'does not update message status if webhook fails for other events' do
    payload = { event: 'conversation_created', conversation: { id: conversation.id }, id: message.id }

    expect(RestClient::Request).to receive(:execute)
      .with(
        method: :post,
        url: url,
        payload: payload.to_json,
        headers: { content_type: :json, accept: :json },
        timeout: 5
      ).and_raise(RestClient::ExceptionWithResponse.new('error', 500)).once

    expect { trigger.execute(url, payload, webhook_type) }.not_to(change { message.reload.status })
  end
end
