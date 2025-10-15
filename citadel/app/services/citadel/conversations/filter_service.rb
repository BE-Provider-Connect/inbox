# frozen_string_literal: true

module Citadel::Conversations::FilterService
  def base_relation
    # Use preload instead of includes for polymorphic assignee to avoid SQL issues
    conversations = @account.conversations.includes(
      :taggings, :inbox, { contact: { avatar_attachment: [:blob] } }, :team, :messages, :contact_inbox
    ).preload(assignee: { avatar_attachment: [:blob] })

    Conversations::PermissionFilterService.new(
      conversations,
      @user,
      @account
    ).perform
  end
end
