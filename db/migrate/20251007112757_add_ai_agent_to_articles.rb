class AddAiAgentToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :ai_agent_enabled, :boolean, default: false, null: false
    add_column :articles, :ai_agent_scope, :integer

    add_index :articles, :ai_agent_enabled
    add_index :articles, :ai_agent_scope
    add_index :articles, [:ai_agent_enabled, :ai_agent_scope]
  end
end
