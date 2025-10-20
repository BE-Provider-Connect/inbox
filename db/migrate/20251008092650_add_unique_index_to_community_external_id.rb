class AddUniqueIndexToCommunityExternalId < ActiveRecord::Migration[7.1]
  def change
    add_index :communities, [:external_id, :account_id], unique: true
  end
end
