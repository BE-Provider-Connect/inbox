class CreateAssistants < ActiveRecord::Migration[7.1]
  def change
    create_table :assistants do |t|
      t.string :name, null: false
      t.jsonb :settings, default: {}
      t.boolean :enabled, default: true
      t.timestamps
    end

    add_index :assistants, :name, unique: true
  end
end
