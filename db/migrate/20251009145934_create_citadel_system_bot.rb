class CreateCitadelSystemBot < ActiveRecord::Migration[7.0]
  def up
    # Create the Citadel system bot (account_id: nil makes it a system bot)
    AgentBot.find_or_create_by!(name: 'Citadel AI', account_id: nil) do |bot|
      bot.description = 'AI-powered customer assistant'
      bot.bot_type = 'webhook'
      bot.outgoing_url = 'ENV:CITADEL_API_ENDPOINT'
    end
  end

  def down
    # Find and destroy the Citadel bot
    citadel_bot = AgentBot.find_by(name: 'Citadel AI', account_id: nil)
    citadel_bot&.destroy!
  end
end
