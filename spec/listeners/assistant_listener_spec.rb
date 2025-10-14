require 'rails_helper'

describe AssistantListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:assistant) { Assistant.instance }

  # Ensure contact_inbox is verified by default for web widget inboxes
  before do
    conversation.contact_inbox&.update!(hmac_verified: true)
    # Stub the ENV variable for all tests
    stub_const('ENV', ENV.to_hash.merge('CITADEL_API_WEBHOOK_URL' => 'https://api.citadel.ai/webhook'))
  end

  describe '#message_created' do
    let(:message) { create(:message, conversation: conversation, inbox: inbox, account: account) }
    let(:event_name) { :message_created.to_s }
    let(:event_obj) do
      Events::Base.new(event_name, Time.zone.now, message: message)
    end

    context 'when conversation is assigned to assistant' do
      before do
        conversation.update!(assignee: assistant)
      end

      it 'triggers webhook for new message' do
        expect(AgentBots::WebhookJob).to receive(:perform_later)
          .with('https://api.citadel.ai/webhook', hash_including(event: 'message_created'), :assistant_webhook)

        listener.message_created(event_obj)
      end
    end

    context 'when conversation is not assigned to assistant' do
      it 'does not trigger webhook' do
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.message_created(event_obj)
      end
    end

    context 'when message is not webhook sendable' do
      before do
        conversation.update!(assignee: assistant)
        allow(message).to receive(:webhook_sendable?).and_return(false)
      end

      it 'does not trigger webhook' do
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.message_created(event_obj)
      end
    end

    context 'when conversation is not verified (web widget)' do
      before do
        conversation.update!(assignee: assistant)
        conversation.contact_inbox.update!(hmac_verified: false)
      end

      it 'does not trigger webhook' do
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.message_created(event_obj)
      end
    end
  end

  describe '#assignee_changed' do
    let(:event_name) { :assignee_changed.to_s }
    let(:event_obj) do
      Events::Base.new(event_name, Time.zone.now, conversation: conversation)
    end

    context 'when conversation is assigned to assistant and verified' do
      before do
        conversation.update!(assignee: assistant)
      end

      it 'triggers webhook' do
        expect(AgentBots::WebhookJob).to receive(:perform_later)
          .with('https://api.citadel.ai/webhook', hash_including(event: 'assignee_changed'), :assistant_webhook)

        listener.assignee_changed(event_obj)
      end
    end

    context 'when conversation is not verified (web widget)' do
      before do
        conversation.update!(assignee: assistant)
        conversation.contact_inbox.update!(hmac_verified: false)
      end

      it 'does not trigger webhook' do
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.assignee_changed(event_obj)
      end
    end
  end

  describe 'verification for non-web-widget inboxes' do
    let(:email_inbox) { create(:inbox, :with_email, account: account) }
    let(:email_conversation) { create(:conversation, account: account, inbox: email_inbox) }
    let(:message) { create(:message, conversation: email_conversation, inbox: email_inbox, account: account) }
    let(:event_name) { :message_created.to_s }
    let(:event_obj) do
      Events::Base.new(event_name, Time.zone.now, message: message)
    end

    before do
      email_conversation.update!(assignee: assistant)
    end

    it 'triggers webhook for non-web-widget inboxes regardless of hmac_verified' do
      expect(AgentBots::WebhookJob).to receive(:perform_later)
        .with('https://api.citadel.ai/webhook', hash_including(event: 'message_created'), :assistant_webhook)

      listener.message_created(event_obj)
    end
  end
end
