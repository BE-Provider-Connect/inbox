class AddAccountIdToCommunities < ActiveRecord::Migration[7.1]
  def change
    add_reference :communities, :account, null: true, foreign_key: true
  end
end
