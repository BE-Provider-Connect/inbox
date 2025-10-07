require 'rails_helper'

RSpec.describe CommunityGroup do
  describe 'validations' do
    subject { build(:community_group) }

    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:external_id) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:communities).dependent(:destroy) }
    it { is_expected.to have_many(:article_community_groups).dependent(:destroy) }
    it { is_expected.to have_many(:articles).through(:article_community_groups) }
  end
end
