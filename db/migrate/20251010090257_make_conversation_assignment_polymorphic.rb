class MakeConversationAssignmentPolymorphic < ActiveRecord::Migration[7.1]
  def change
    # Add polymorphic columns for assignee
    add_column :conversations, :assignee_type, :string
    add_index :conversations, [:assignee_type, :assignee_id]

    # Backfill existing data - all current assignees are Users
    reversible do |dir|
      dir.up do
        Conversation.update_all(assignee_type: 'User')
      end
    end

    # Messages table already has sender_type and sender_id columns
    # Just backfill existing message senders
    reversible do |dir|
      dir.up do
        Message.where.not(sender_id: nil).where(sender_type: nil).update_all(sender_type: 'User')
      end
    end
  end
end
