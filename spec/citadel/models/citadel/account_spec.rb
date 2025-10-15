# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'associations' do
    it { expect(Account.new).to have_many(:communities).dependent(:destroy_async) }
    it { expect(Account.new).to have_many(:community_groups).dependent(:destroy_async) }
  end

  describe 'external_id validations' do
    it 'validates uniqueness of external_id' do
      create(:account, external_id: 'org_123')
      account2 = build(:account, external_id: 'org_123')

      expect(account2).not_to be_valid
      expect(account2.errors[:external_id]).to include('has already been taken')
    end

    it 'allows nil external_id' do
      account = build(:account, external_id: nil)
      expect(account).to be_valid
    end

    it 'allows multiple accounts with nil external_id' do
      create(:account, external_id: nil)
      account2 = build(:account, external_id: nil)
      expect(account2).to be_valid
    end

    it 'allows unique external_id values' do
      create(:account, external_id: 'org_123')
      account2 = build(:account, external_id: 'org_456')
      expect(account2).to be_valid
    end
  end

  describe '#webhook_data' do
    it 'includes external_id in webhook data' do
      account = create(:account, external_id: 'org_123')
      webhook_data = account.webhook_data

      expect(webhook_data[:external_id]).to eq('org_123')
    end
  end
end
