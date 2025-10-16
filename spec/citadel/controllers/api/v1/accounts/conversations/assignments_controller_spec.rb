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
    end
  end
end
