class CreateArticleAssociations < ActiveRecord::Migration[7.1]
  def change
    create_table :article_community_groups do |t|
      t.references :article, null: false, foreign_key: true
      t.references :community_group, null: false, foreign_key: true
      t.timestamps
    end

    create_table :article_communities do |t|
      t.references :article, null: false, foreign_key: true
      t.references :community, null: false, foreign_key: true
      t.timestamps
    end

    add_index :article_community_groups, [:article_id, :community_group_id],
              unique: true, name: 'idx_article_community_groups_unique'
    add_index :article_communities, [:article_id, :community_id],
              unique: true, name: 'idx_article_communities_unique'
  end
end
