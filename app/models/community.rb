# == Schema Information
#
# Table name: communities
#
#  id                 :bigint           not null, primary key
#  external_id        :string           not null
#  name               :string           not null
#  synced_at          :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  community_group_id :bigint
#
# Indexes
#
#  index_communities_on_community_group_id  (community_group_id)
#  index_communities_on_external_id         (external_id) UNIQUE
#
class Community < ApplicationRecord
  belongs_to :account
  belongs_to :community_group, optional: true
  has_many :article_communities, dependent: :destroy
  has_many :articles, through: :article_communities

  validates :external_id, presence: true, uniqueness: { scope: :account_id }
  validates :name, presence: true
  validates :account_id, presence: true

  scope :with_articles, -> { joins(:articles).distinct }
  scope :for_community_group, ->(group_id) { where(community_group_id: group_id) }
end
