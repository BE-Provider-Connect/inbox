require 'rails_helper'

RSpec.describe CommunitySyncService do
  subject(:sync_service) { described_class.new }

  let(:api_client) { instance_double(Integrations::CitadelApi::Client) }
  let(:community_groups_data) do
    [
      { 'id' => 'group-1', 'name' => 'Group One', 'organizationId' => 'org-1' },
      { 'id' => 'group-2', 'name' => 'Group Two', 'organizationId' => 'org-1' }
    ]
  end

  let(:communities_data) do
    [
      { 'id' => 'comm-1', 'name' => 'Community One', 'communityGroupId' => 'group-1', 'organizationId' => 'org-1' },
      { 'id' => 'comm-2', 'name' => 'Community Two', 'communityGroupId' => 'group-1', 'organizationId' => 'org-1' },
      { 'id' => 'comm-3', 'name' => 'Community Three', 'communityGroupId' => 'group-2', 'organizationId' => 'org-1' }
    ]
  end

  before do
    allow(Integrations::CitadelApi::Client).to receive(:new).and_return(api_client)
    allow(api_client).to receive(:fetch_community_groups).and_return(community_groups_data)
    allow(api_client).to receive(:fetch_communities).and_return(communities_data)
  end

  describe '#perform' do
    context 'with successful sync' do
      it 'creates a new API client' do
        sync_service.perform
        expect(Integrations::CitadelApi::Client).to have_received(:new)
      end

      it 'fetches community groups from the API' do
        sync_service.perform
        expect(api_client).to have_received(:fetch_community_groups)
      end

      it 'fetches communities from the API' do
        sync_service.perform
        expect(api_client).to have_received(:fetch_communities)
      end

      it 'creates new community groups' do
        expect { sync_service.perform }.to change(CommunityGroup, :count).by(2)
      end

      it 'creates new communities' do
        expect { sync_service.perform }.to change(Community, :count).by(3)
      end

      it 'returns sync statistics' do
        stats = sync_service.perform
        expect(stats).to eq({
                              community_groups: { created: 2, updated: 0 },
                              communities: { created: 3, updated: 0 }
                            })
      end

      it 'sets synced_at timestamp on community groups' do
        freeze_time do
          sync_service.perform
          group = CommunityGroup.find_by(external_id: 'group-1')
          expect(group.synced_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'sets synced_at timestamp on communities' do
        freeze_time do
          sync_service.perform
          community = Community.find_by(external_id: 'comm-1')
          expect(community.synced_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context 'with existing records' do
      let!(:existing_group) { create(:community_group, external_id: 'group-1', name: 'Old Name') }
      let!(:existing_community) do
        create(:community, external_id: 'comm-1', name: 'Old Community Name', community_group: existing_group)
      end

      it 'updates existing community groups' do
        expect { sync_service.perform }.to change(CommunityGroup, :count).by(1) # Only creates group-2
        expect(existing_group.reload.name).to eq('Group One')
      end

      it 'updates existing communities' do
        expect { sync_service.perform }.to change(Community, :count).by(2) # Only creates comm-2 and comm-3
        expect(existing_community.reload.name).to eq('Community One')
      end

      it 'returns correct sync statistics' do
        stats = sync_service.perform
        expect(stats).to eq({
                              community_groups: { created: 1, updated: 1 },
                              communities: { created: 2, updated: 1 }
                            })
      end

      it 'updates synced_at timestamp on existing records' do
        old_time = 1.day.ago
        existing_group.update!(synced_at: old_time)

        freeze_time do
          sync_service.perform
          expect(existing_group.reload.synced_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context 'with community group relationships' do
      it 'correctly associates communities with community groups' do
        sync_service.perform

        community = Community.find_by(external_id: 'comm-1')
        group = CommunityGroup.find_by(external_id: 'group-1')

        expect(community.community_group).to eq(group)
      end

      it 'syncs groups before communities to ensure relationships exist' do
        sync_service.perform

        community = Community.find_by(external_id: 'comm-3')
        group = CommunityGroup.find_by(external_id: 'group-2')

        expect(community.community_group).to eq(group)
      end
    end

    context 'with API errors' do
      context 'when fetch_community_groups fails' do
        before do
          allow(api_client).to receive(:fetch_community_groups).and_raise(StandardError, 'API Error')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs the error' do
          expect { sync_service.perform }.to raise_error(StandardError)
          expect(Rails.logger).to have_received(:error).with('Community sync failed: API Error')
        end

        it 'raises the error' do
          expect { sync_service.perform }.to raise_error(StandardError, 'API Error')
        end
      end

      context 'when fetch_communities fails' do
        before do
          allow(api_client).to receive(:fetch_communities).and_raise(StandardError, 'Connection timeout')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs the error' do
          expect { sync_service.perform }.to raise_error(StandardError)
          expect(Rails.logger).to have_received(:error).with('Community sync failed: Connection timeout')
          expect(Rails.logger).to have_received(:error).at_least(:once) # backtrace logged
        end

        it 'raises the error' do
          expect { sync_service.perform }.to raise_error(StandardError, 'Connection timeout')
        end
      end
    end

    context 'with empty data from API' do
      before do
        allow(api_client).to receive(:fetch_community_groups).and_return([])
        allow(api_client).to receive(:fetch_communities).and_return([])
      end

      it 'completes successfully with zero stats' do
        stats = sync_service.perform
        expect(stats).to eq({
                              community_groups: { created: 0, updated: 0 },
                              communities: { created: 0, updated: 0 }
                            })
      end

      it 'does not create any records' do
        expect { sync_service.perform }.not_to change(CommunityGroup, :count)
        expect { sync_service.perform }.not_to change(Community, :count)
      end
    end

    context 'with missing community group reference' do
      let(:communities_with_missing_group) do
        [
          { 'id' => 'comm-orphan', 'name' => 'Orphan Community', 'communityGroupId' => 'missing-group', 'organizationId' => 'org-1' }
        ]
      end

      before do
        allow(api_client).to receive(:fetch_communities).and_return(communities_with_missing_group)
      end

      it 'creates community with nil community_group when group not found' do
        sync_service.perform
        community = Community.find_by(external_id: 'comm-orphan')
        expect(community.community_group).to be_nil
      end
    end
  end
end
