class AddPrivateToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :private, :boolean, default: false, null: false
    add_index :articles, :private
  end
end
