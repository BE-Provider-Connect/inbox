module Seeders::CommunitySeeder
  def self.seed_community_groups_and_communities
    # Community Groups
    downtown_group = CommunityGroup.find_or_create_by!(external_id: 'cg_downtown_001') do |cg|
      cg.name = 'Downtown Properties'
      cg.synced_at = Time.current
    end

    waterfront_group = CommunityGroup.find_or_create_by!(external_id: 'cg_waterfront_002') do |cg|
      cg.name = 'Waterfront Properties'
      cg.synced_at = Time.current
    end

    suburban_group = CommunityGroup.find_or_create_by!(external_id: 'cg_suburban_003') do |cg|
      cg.name = 'Suburban Properties'
      cg.synced_at = Time.current
    end

    # Communities
    Community.find_or_create_by!(external_id: 'comm_oak_tower') do |c|
      c.name = 'Oak Tower'
      c.community_group = downtown_group
      c.synced_at = Time.current
    end

    Community.find_or_create_by!(external_id: 'comm_maple_plaza') do |c|
      c.name = 'Maple Plaza'
      c.community_group = downtown_group
      c.synced_at = Time.current
    end

    Community.find_or_create_by!(external_id: 'comm_harbor_view') do |c|
      c.name = 'Harbor View Residences'
      c.community_group = waterfront_group
      c.synced_at = Time.current
    end

    Community.find_or_create_by!(external_id: 'comm_bay_marina') do |c|
      c.name = 'Bay Marina Apartments'
      c.community_group = waterfront_group
      c.synced_at = Time.current
    end

    Community.find_or_create_by!(external_id: 'comm_garden_heights') do |c|
      c.name = 'Garden Heights'
      c.community_group = suburban_group
      c.synced_at = Time.current
    end

    Community.find_or_create_by!(external_id: 'comm_sunset_villas') do |c|
      c.name = 'Sunset Villas'
      c.community_group = suburban_group
      c.synced_at = Time.current
    end

    # Independent community without a group
    Community.find_or_create_by!(external_id: 'comm_standalone_loft') do |c|
      c.name = 'Standalone Loft Complex'
      c.community_group = nil
      c.synced_at = Time.current
    end
  end
end
