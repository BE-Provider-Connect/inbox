class CreateCommunityGroupsAndCommunities < ActiveRecord::Migration[7.1]
  def change
    create_table :community_groups do |t|
      t.string :external_id, null: false
      t.string :name, null: false
      t.datetime :synced_at
      t.timestamps
    end

    create_table :communities do |t|
      t.string :external_id, null: false
      t.string :name, null: false
      t.references :community_group, foreign_key: true
      t.datetime :synced_at
      t.timestamps
    end

    add_index :community_groups, :external_id, unique: true
    add_index :communities, :external_id, unique: true
  end
end
