# == Schema Information
#
# Table name: article_communities
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  article_id   :bigint           not null
#  community_id :bigint           not null
#
# Indexes
#
#  idx_article_communities_unique                    (article_id,community_id) UNIQUE
#  index_article_communities_on_article_id           (article_id)
#  index_article_communities_on_community_id         (community_id)
#
class ArticleCommunity < ApplicationRecord
  belongs_to :article
  belongs_to :community

  validates :article_id, uniqueness: { scope: :community_id }
end
