class AddAccountIdToCommunityGroups < ActiveRecord::Migration[7.1]
  def change
    add_reference :community_groups, :account, null: true, foreign_key: true
  end
end
