json.array! @community_groups do |community_group|
  json.id community_group.id
  json.external_id community_group.external_id
  json.name community_group.name
  json.synced_at community_group.synced_at
end
