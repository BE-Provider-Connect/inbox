# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V2::Reports::AgentSummaryBuilder do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { Assistant.instance }

  let(:params) do
    {
      type: :agent,
      since: 30.days.ago.to_i.to_s,
      until: Time.current.to_i.to_s,
      business_hours: false
    }
  end

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    assistant.update!(enabled: true)
  end

  describe '#build' do
    context 'with conversations assigned to users and assistant' do
      before do
        # Create conversation assigned to user
        user_conversation = create(:conversation, account: account, inbox: inbox, assignee: agent, assignee_type: 'User')
        create(:reporting_event,
               account: account,
               name: 'conversation_resolved',
               value: 100,
               user_id: agent.id,
               conversation_id: user_conversation.id,
               created_at: 1.day.ago)

        # Create conversation assigned to assistant
        assistant_conversation = create(:conversation, account: account, inbox: inbox, assignee: assistant,
                                                       assignee_type: 'Assistant')
        create(:reporting_event,
               account: account,
               name: 'conversation_resolved',
               value: 50,
               user_id: assistant.id,
               conversation_id: assistant_conversation.id,
               created_at: 1.day.ago)
      end

      it 'includes assistant in the report' do
        builder = described_class.new(account: account, params: params)
        report = builder.build

        # Should have stats for both agent and assistant
        expect(report.size).to eq(2) # 1 user + 1 assistant

        agent_stats = report.find { |r| r[:id] == agent.id }
        expect(agent_stats).to be_present
        expect(agent_stats[:resolved_conversations_count]).to eq(1)

        assistant_stats = report.find { |r| r[:id] == "assistant_#{assistant.id}" }
        expect(assistant_stats).to be_present
        expect(assistant_stats[:name]).to eq(assistant.name)
        expect(assistant_stats[:type]).to eq('assistant')
        expect(assistant_stats[:resolved_conversations_count]).to eq(1)
      end
    end

    context 'when assistant is disabled' do
      before do
        assistant.update!(enabled: false)
      end

      it 'does not include assistant in the report' do
        builder = described_class.new(account: account, params: params)
        report = builder.build

        assistant_stats = report.find { |r| r[:id] == "assistant_#{assistant.id}" }
        expect(assistant_stats).to be_nil
      end
    end
  end
end
