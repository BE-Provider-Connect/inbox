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
    account = find_account_for_organization(group_data['organizationId'], group_data['id'], 'community group')
    return unless account

    community_group = find_or_initialize_community_group(group_data, account)
    update_community_group_stats(community_group)
    update_community_group(community_group, group_data)
  end

  def sync_communities
    communities_data = @client.fetch_communities

    communities_data.each do |community_data|
      sync_community(community_data)
    end
  end

  def sync_community(community_data)
    account = find_account_for_organization(community_data['organizationId'], community_data['id'], 'community')
    return unless account

    community = find_or_initialize_community(community_data, account)
    update_community_stats(community)

    community_group = find_community_group(community_data['communityGroupId'], account)
    update_community(community, community_data, community_group)
  end

  def find_account_for_organization(organization_id, record_id, record_type)
    account = Account.find_by(external_id: organization_id)
    Rails.logger.warn "No account found for organization #{organization_id}, skipping #{record_type} #{record_id}" unless account
    account
  end

  def find_or_initialize_community_group(group_data, account)
    CommunityGroup.find_or_initialize_by(
      external_id: group_data['id'],
      account_id: account.id
    )
  end

  def update_community_group_stats(community_group)
    if community_group.new_record?
      @stats[:community_groups][:created] += 1
    else
      @stats[:community_groups][:updated] += 1
    end
  end

  def update_community_group(community_group, group_data)
    community_group.update!(
      name: group_data['name'],
      synced_at: Time.current
    )
  end

  def find_or_initialize_community(community_data, account)
    Community.find_or_initialize_by(
      external_id: community_data['id'],
      account_id: account.id
    )
  end

  def update_community_stats(community)
    if community.new_record?
      @stats[:communities][:created] += 1
    else
      @stats[:communities][:updated] += 1
    end
  end

  def find_community_group(community_group_id, account)
    return if community_group_id.blank?

    CommunityGroup.find_by(external_id: community_group_id, account_id: account.id)
  end

  def update_community(community, community_data, community_group)
    community.update!(
      name: community_data['name'],
      community_group: community_group,
      synced_at: Time.current
    )
  end
end
