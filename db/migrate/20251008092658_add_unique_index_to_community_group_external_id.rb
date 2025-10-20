class AddUniqueIndexToCommunityGroupExternalId < ActiveRecord::Migration[7.1]
  def change
    add_index :community_groups, [:external_id, :account_id], unique: true
  end
end
