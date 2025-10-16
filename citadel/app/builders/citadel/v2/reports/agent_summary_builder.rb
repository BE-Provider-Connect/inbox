# frozen_string_literal: true

module Citadel::V2::Reports::AgentSummaryBuilder
  private

  def load_data
    @conversations_count = fetch_conversations_count
    @resolved_count = fetch_resolved_count
    @avg_resolution_time = fetch_average_time('conversation_resolved')
    @avg_first_response_time = fetch_average_time('first_response')
    @avg_reply_time = fetch_average_time('reply_time')
  end

  def fetch_conversations_count
    # Single query grouping by composite key: assignee_type || '_' || assignee_id
    account.conversations
           .where(created_at: range)
           .where.not(assignee_id: nil)
           .group("COALESCE(assignee_type, 'User') || '_' || assignee_id")
           .count
           .transform_keys { |key| parse_composite_key(key) }
  end

  def reporting_events
    @reporting_events ||= account.reporting_events
                                 .joins(:conversation)
                                 .where(created_at: range)
  end

  def fetch_average_time(event_name)
    # Single query with composite grouping
    value_key = ActiveModel::Type::Boolean.new.cast(params[:business_hours]).present? ? :value_in_business_hours : :value

    reporting_events
      .where(name: event_name)
      .group("COALESCE(conversations.assignee_type, 'User') || '_' || conversations.assignee_id")
      .average(value_key)
      .transform_keys { |key| parse_composite_key(key) }
  end

  def fetch_resolved_count
    # Single query with composite grouping
    reporting_events
      .where(name: 'conversation_resolved')
      .group("COALESCE(conversations.assignee_type, 'User') || '_' || conversations.assignee_id")
      .count
      .transform_keys { |key| parse_composite_key(key) }
  end

  def parse_composite_key(composite_key)
    # Parse "User_1" -> 1 (integer), "Assistant_1" -> "assistant_1" (string)
    # Keep them as different types so they don't collide in the hash
    type, id = composite_key.split('_', 2)
    type == 'Assistant' ? "assistant_#{id}" : id.to_i
  end

  def build_agent_stats(account_user)
    user_id = account_user.user_id
    {
      id: user_id,
      conversations_count: conversations_count[user_id] || 0,
      resolved_conversations_count: resolved_count[user_id] || 0,
      avg_resolution_time: avg_resolution_time[user_id],
      avg_first_response_time: avg_first_response_time[user_id],
      avg_reply_time: avg_reply_time[user_id]
    }
  end

  def prepare_report
    # Include both users and enabled assistants in the report
    agents_report = account.account_users.map do |account_user|
      build_agent_stats(account_user)
    end

    # Add Assistant if enabled
    assistant = Assistant.instance
    agents_report << build_assistant_stats(assistant) if assistant&.enabled?

    agents_report
  end

  def build_assistant_stats(assistant)
    assistant_key = "assistant_#{assistant.id}"
    {
      id: "assistant_#{assistant.id}", # Use prefixed ID to avoid collision with user IDs
      name: assistant.name,
      type: 'assistant',
      conversations_count: conversations_count[assistant_key] || 0,
      resolved_conversations_count: resolved_count[assistant_key] || 0,
      avg_resolution_time: avg_resolution_time[assistant_key],
      avg_first_response_time: avg_first_response_time[assistant_key],
      avg_reply_time: avg_reply_time[assistant_key]
    }
  end
end
