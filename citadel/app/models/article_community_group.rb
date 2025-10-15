# == Schema Information
#
# Table name: article_community_groups
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  article_id         :bigint           not null
#  community_group_id :bigint           not null
#
# Indexes
#
#  idx_article_community_groups_unique                            (article_id,community_group_id) UNIQUE
#  index_article_community_groups_on_article_id                   (article_id)
#  index_article_community_groups_on_community_group_id           (community_group_id)
#
class ArticleCommunityGroup < ApplicationRecord
  belongs_to :article
  belongs_to :community_group

  validates :article_id, uniqueness: { scope: :community_group_id }
end
