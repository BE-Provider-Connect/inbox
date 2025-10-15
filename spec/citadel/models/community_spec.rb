require 'rails_helper'

RSpec.describe Community, type: :model do
  describe 'validations' do
    subject { build(:community) }

    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:external_id).scoped_to(:account_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:community_group).optional }
    it { is_expected.to have_many(:article_communities).dependent(:destroy) }
    it { is_expected.to have_many(:articles).through(:article_communities) }
  end
end
