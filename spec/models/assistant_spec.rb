require 'rails_helper'

RSpec.describe Assistant do
  describe '.instance' do
    it 'creates a singleton assistant' do
      assistant = described_class.instance
      expect(assistant).to be_persisted
      expect(assistant.name).to eq('Citadel AI')
    end

    it 'returns the same instance on subsequent calls' do
      assistant1 = described_class.instance
      assistant2 = described_class.instance
      expect(assistant1.id).to eq(assistant2.id)
    end
  end

  describe '#webhook_url' do
    it 'returns the webhook URL from environment' do
      stub_const('ENV', ENV.to_hash.merge('CITADEL_API_WEBHOOK_URL' => 'https://api.citadel.ai/webhook'))
      assistant = described_class.instance
      expect(assistant.webhook_url).to eq('https://api.citadel.ai/webhook')
    end
  end

  describe '#outgoing_url' do
    it 'aliases to webhook_url for compatibility' do
      stub_const('ENV', ENV.to_hash.merge('CITADEL_API_WEBHOOK_URL' => 'https://api.citadel.ai/webhook'))
      assistant = described_class.instance
      expect(assistant.outgoing_url).to eq(assistant.webhook_url)
    end
  end

  describe 'agent interface methods' do
    let(:assistant) { described_class.instance }

    it 'responds to agent interface methods' do
      expect(assistant.agent?).to be(true)
      expect(assistant.assistant?).to be(true)
      expect(assistant.availability_status).to eq('online')
      expect(assistant.display_name).to eq('Citadel AI')
    end
  end

  describe 'associations' do
    let(:assistant) { described_class.instance }
    let(:conversation) { create(:conversation) }

    it 'can be assigned to conversations' do
      conversation.assignee = assistant
      conversation.save!
      expect(conversation.assignee).to eq(assistant)
      expect(conversation.assignee_type).to eq('Assistant')
    end

    it 'can send messages' do
      message = create(:message, sender: assistant)
      expect(message.sender).to eq(assistant)
      expect(message.sender_type).to eq('Assistant')
    end
  end
end
