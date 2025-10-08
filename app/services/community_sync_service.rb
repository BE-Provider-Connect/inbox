class CommunitySyncService
  def initialize
    @client = Integrations::CitadelApi::Client.new
    @stats = { community_groups: { created: 0, updated: 0 }, communities: { created: 0, updated: 0 } }
  end

  def perform
    Rails.logger.info 'Starting community sync from Citadel API'

    sync_community_groups
    sync_communities

    Rails.logger.info "Community sync completed: #{@stats}"
    @stats
  rescue StandardError => e
    Rails.logger.error "Community sync failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  private

  def sync_community_groups
    community_groups_data = @client.fetch_community_groups

    community_groups_data.each do |group_data|
      sync_community_group(group_data)
    end
  end

  def sync_community_group(group_data)
    account = Account.find_by(external_id: group_data['organizationId'])

    unless account
      Rails.logger.warn "No account found for organization #{group_data['organizationId']}, skipping group #{group_data['id']}"
      return
    end

    community_group = CommunityGroup.find_or_initialize_by(
      external_id: group_data['id'],
      account_id: account.id
    )

    if community_group.new_record?
      @stats[:community_groups][:created] += 1
    else
      @stats[:community_groups][:updated] += 1
    end

    community_group.update!(
      name: group_data['name'],
      synced_at: Time.current
    )
  end

  def sync_communities
    communities_data = @client.fetch_communities

    communities_data.each do |community_data|
      sync_community(community_data)
    end
  end

  def sync_community(community_data)
    account = Account.find_by(external_id: community_data['organizationId'])

    unless account
      Rails.logger.warn "No account found for organization #{community_data['organizationId']}, skipping community #{community_data['id']}"
      return
    end

    community = Community.find_or_initialize_by(
      external_id: community_data['id'],
      account_id: account.id
    )

    if community.new_record?
      @stats[:communities][:created] += 1
    else
      @stats[:communities][:updated] += 1
    end

    # Find the community group by external_id within the same account
    community_group = if community_data['communityGroupId'].present?
                        CommunityGroup.find_by(
                          external_id: community_data['communityGroupId'],
                          account_id: account.id
                        )
                      end

    community.update!(
      name: community_data['name'],
      community_group: community_group,
      synced_at: Time.current
    )
  end
end
