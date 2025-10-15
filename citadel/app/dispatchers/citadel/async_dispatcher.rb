# frozen_string_literal: true

module Citadel::AsyncDispatcher
  def listeners
    super + [AssistantListener.instance]
  end
end
