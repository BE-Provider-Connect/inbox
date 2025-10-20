# == Schema Information
#
# Table name: assistants
#
#  id         :bigint           not null, primary key
#  enabled    :boolean          default(TRUE)
#  name       :string           not null
#  settings   :jsonb            default({})
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_assistants_on_name  (name) UNIQUE
#
class Assistant < ApplicationRecord
  # Singleton pattern - only one assistant for the entire system
  def self.instance
    first_or_create!(name: 'Citadel AI')
  end

  # Associations as assignee
  has_many :assigned_conversations,
           class_name: 'Conversation',
           as: :assignee,
           dependent: :nullify

  # Associations as message sender
  has_many :messages,
           as: :sender,
           dependent: :nullify

  # Get webhook URL from environment
  def webhook_url
    ENV.fetch('CITADEL_API_WEBHOOK_URL', nil)
  end

  # Alias for compatibility with AgentBot patterns
  def outgoing_url
    webhook_url
  end

  # Agent-like interface methods
  def agent?
    true
  end

  def assistant?
    true
  end

  def availability_status
    enabled? ? 'online' : 'offline'
  end

  def available_for?(_account)
    enabled?
  end

  # Display properties
  def display_name
    name
  end

  def avatar_url
    '/assistant-avatar.png' # Can be customized later
  end

  # Push event data for websocket/event streaming
  def push_event_data
    {
      id: "assistant_#{id}",  # Prefix ID to avoid collision with User IDs
      name: name,
      email: 'assistant@citadel.ai',
      available_name: name,
      avatar_url: avatar_url,
      type: 'assistant'
    }
  end

  # Permission methods
  def can_read_message?
    true
  end

  def can_reply_message?
    enabled?
  end
end
