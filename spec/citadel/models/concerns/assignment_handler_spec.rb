require 'rails_helper'

RSpec.describe Citadel::AssignmentHandler do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { Assistant.instance }

  before do
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
  end

  describe 'polymorphic assignee changes' do
    context 'when changing from User to Assistant with same ID' do
      # Create user with ID matching the Assistant's ID
      let(:user) { create(:user, id: assistant.id, account: account) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

      it 'dispatches ASSIGNEE_CHANGED event' do
        # Verify initial state (this triggers the lazy creation of conversation)
        expect(conversation.assignee_id).to eq(assistant.id)
        expect(conversation.assignee_type).to eq('User')

        # This simulates User#X -> Assistant#X (same ID, different type)
        conversation.update!(assignee: assistant)

        # Verify the type actually changed
        expect(conversation.reload.assignee_id).to eq(assistant.id)
        expect(conversation.reload.assignee_type).to eq('Assistant')

        # The event should be dispatched with the assignee_type change from User to Assistant
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(
            Conversation::ASSIGNEE_CHANGED,
            kind_of(Time),
            hash_including(conversation: conversation, changed_attributes: hash_including('assignee_type' => %w[User Assistant]))
          ).at_least(:once)
      end

      it 'creates assignee change activity message' do
        Current.user = user

        expect do
          conversation.update!(assignee: assistant)
        end.to have_enqueued_job(Conversations::ActivityMessageJob)
          .with(conversation, hash_including(
                                message_type: :activity,
                                content: /Assigned to Citadel AI/
                              ))
      end
    end

    context 'when changing from Assistant to User with same ID' do
      let(:user) { create(:user, id: assistant.id, account: account) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: assistant) }

      it 'dispatches ASSIGNEE_CHANGED event' do
        # Verify initial state
        expect(conversation.assignee_id).to eq(assistant.id)
        expect(conversation.assignee_type).to eq('Assistant')

        conversation.update!(assignee: user)

        # Verify the type changed
        expect(conversation.reload.assignee_id).to eq(assistant.id)
        expect(conversation.reload.assignee_type).to eq('User')

        # The event should be dispatched with the assignee_type change from Assistant to User
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(
            Conversation::ASSIGNEE_CHANGED,
            kind_of(Time),
            hash_including(conversation: conversation, changed_attributes: hash_including('assignee_type' => %w[Assistant User]))
          ).at_least(:once)
      end
    end

    context 'when both assignee_id and assignee_type change' do
      let(:user) { create(:user, account: account) }
      let(:another_user) { create(:user, account: account) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

      it 'dispatches ASSIGNEE_CHANGED event' do
        conversation.update!(assignee: another_user)

        # Should fire with the assignee_id change
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(
            Conversation::ASSIGNEE_CHANGED,
            kind_of(Time),
            hash_including(conversation: conversation)
          ).at_least(:once)
      end
    end
  end
end
