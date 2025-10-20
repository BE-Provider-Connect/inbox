# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParticipationListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox) }

  describe '#assignee_changed' do
    let(:event_name) { :assignee_changed }

    context 'when assignee is an Assistant' do
      it 'does not create a conversation participant' do
        assistant = Assistant.instance
        conversation.update!(assignee: assistant, assignee_type: 'Assistant')

        event = Events::Base.new(event_name, Time.zone.now, conversation: conversation)
        initial_participant_count = conversation.conversation_participants.count

        listener.assignee_changed(event)

        expect(conversation.conversation_participants.count).to eq(initial_participant_count)
        expect(conversation.conversation_participants.map(&:user_id)).not_to include(assistant.id)
      end
    end

    context 'when assignee is a User' do
      it 'creates a conversation participant' do
        agent = create(:user, account: account, role: :agent)
        create(:inbox_member, inbox: inbox, user: agent)
        conversation.update!(assignee: agent, assignee_type: 'User')

        event = Events::Base.new(event_name, Time.zone.now, conversation: conversation)
        initial_participant_count = conversation.conversation_participants.count

        listener.assignee_changed(event)

        expect(conversation.conversation_participants.count).to eq(initial_participant_count + 1)
        expect(conversation.conversation_participants.map(&:user_id)).to include(agent.id)
      end
    end
  end
end
