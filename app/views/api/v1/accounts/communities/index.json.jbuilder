json.array! @communities do |community|
  json.id community.id
  json.external_id community.external_id
  json.name community.name
  json.community_group_id community.community_group_id
  json.synced_at community.synced_at
  if community.community_group.present?
    json.community_group do
      json.id community.community_group.id
      json.name community.community_group.name
    end
  end
end
