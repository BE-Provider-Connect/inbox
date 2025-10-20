# == Schema Information
#
# Table name: community_groups
#
#  id          :bigint           not null, primary key
#  external_id :string           not null
#  name        :string           not null
#  synced_at   :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_community_groups_on_external_id  (external_id) UNIQUE
#
class CommunityGroup < ApplicationRecord
  belongs_to :account
  has_many :communities, dependent: :destroy
  has_many :article_community_groups, dependent: :destroy
  has_many :articles, through: :article_community_groups

  validates :external_id, presence: true, uniqueness: { scope: :account_id }
  validates :name, presence: true
  validates :account_id, presence: true

  scope :with_articles, -> { joins(:articles).distinct }
end
