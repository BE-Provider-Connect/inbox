json.id @community_group.id
json.external_id @community_group.external_id
json.name @community_group.name
json.synced_at @community_group.synced_at
json.communities @community_group.communities do |community|
  json.id community.id
  json.external_id community.external_id
  json.name community.name
end
