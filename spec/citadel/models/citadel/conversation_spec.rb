# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Citadel::Conversation extensions', type: :model do
  describe 'polymorphic assignee' do
    let(:conversation) { create(:conversation) }
    let(:user) { create(:user) }
    let(:assistant) { Assistant.instance }

    it 'can be assigned to a user' do
      conversation.assignee = user
      conversation.save!
      expect(conversation.assignee_type).to eq('User')
      expect(conversation.assignee_id).to eq(user.id)
      expect(conversation.assignee).to eq(user)
    end

    it 'can be assigned to an assistant' do
      conversation.assignee = assistant
      conversation.save!
      expect(conversation.assignee_type).to eq('Assistant')
      expect(conversation.assignee_id).to eq(assistant.id)
      expect(conversation.assignee).to eq(assistant)
    end

    it 'assigned_to scope works with polymorphic assignee' do
      conversation.update!(assignee: user)
      expect(Conversation.assigned_to(user)).to include(conversation)

      assistant_conversation = create(:conversation, assignee: assistant)
      expect(Conversation.assigned_to(assistant)).to include(assistant_conversation)
      expect(Conversation.assigned_to(assistant)).not_to include(conversation)
    end
  end
end
