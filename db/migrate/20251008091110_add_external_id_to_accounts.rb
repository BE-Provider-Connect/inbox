class AddExternalIdToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :external_id, :string
    add_index :accounts, :external_id, unique: true
  end
end
