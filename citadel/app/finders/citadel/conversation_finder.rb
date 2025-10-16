# frozen_string_literal: true

module Citadel::ConversationFinder
  private

  def conversations_base_query
    # Cannot use includes with polymorphic associations, use preload instead
    @conversations.includes(
      :taggings, :inbox, { contact: { avatar_attachment: [:blob] } }, :team, :contact_inbox
    ).preload(assignee: { avatar_attachment: [:blob] })
  end
end
