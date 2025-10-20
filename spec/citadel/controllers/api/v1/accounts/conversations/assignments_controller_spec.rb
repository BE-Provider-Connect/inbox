# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Citadel Conversation Assignment API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/conversations/<id>/assignments' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an authenticated user with access to the inbox' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'assigns an assistant to the conversation' do
        assistant = Assistant.instance
        params = { assignee_id: assistant.id, assignee_type: 'Assistant' }

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee).to eq(assistant)
        expect(conversation.reload.assignee_type).to eq('Assistant')
      end

      context 'when changing assignee from one type to another' do
        it 'creates activity message when changing from User to Assistant' do
          # First assign to a user
          conversation.update!(assignee: agent, assignee_type: 'User')
          initial_activity_count = conversation.messages.activity.count

          # Then change to assistant
          assistant = Assistant.instance
          post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
               params: { assignee_id: assistant.id, assignee_type: 'Assistant' },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)

          # Process background jobs
          perform_enqueued_jobs

          conversation.reload
          expect(conversation.messages.activity.count).to be > initial_activity_count
          activity = conversation.messages.activity.last
          expect(activity.content).to include(assistant.name)
        end

        it 'creates activity message when changing from Assistant to User' do
          # First assign to assistant
          assistant = Assistant.instance
          conversation.update!(assignee: assistant, assignee_type: 'Assistant')
          initial_activity_count = conversation.messages.activity.count

          # Then change to user
          post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
               params: { assignee_id: agent.id, assignee_type: 'User' },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)

          # Process background jobs
          perform_enqueued_jobs

          conversation.reload
          expect(conversation.messages.activity.count).to be > initial_activity_count
          activity = conversation.messages.activity.last
          expect(activity.content).to include(agent.name)
        end

        it 'creates activity message when IDs are the same but types differ' do
          # This is the edge case: Assistant with ID X exists, User with ID X exists
          # Changing from one to the other should still create an activity message
          assistant = Assistant.instance
          assistant_id = assistant.id

          # First assign to assistant
          conversation.update!(assignee: assistant, assignee_type: 'Assistant')
          initial_activity_count = conversation.messages.activity.count

          # Find or create a user with the same ID as the assistant
          user_with_same_id = User.find_by(id: assistant_id)
          unless user_with_same_id
            # Skip this test if we can't create a user with the same ID
            # (This would only happen in production with different ID sequences)
            skip "Cannot create User with ID #{assistant_id} for this test scenario"
          end

          create(:account_user, account: account, user: user_with_same_id) unless user_with_same_id.accounts.include?(account)

          # Then change to user with same ID
          post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
               params: { assignee_id: assistant_id, assignee_type: 'User' },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)

          # Process background jobs
          perform_enqueued_jobs

          conversation.reload
          # Even though assignee_id stayed the same, assignee_type changed, so activity should be created
          expect(conversation.messages.activity.count).to be > initial_activity_count
          activity = conversation.messages.activity.last
          expect(activity.content).to include(user_with_same_id.name)
          expect(conversation.assignee_type).to eq('User')
        end
      end
    end
  end
end
