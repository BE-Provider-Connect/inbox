json.id article.id
json.account_id article.account_id
json.account_external_id article.account.external_id
json.portal_id article.portal_id
json.category_id article.category_id
json.title article.title
json.content article.content
json.description article.description
json.slug article.slug
json.status article.status
json.locale article.locale
json.position article.position
json.views article.views
json.ai_agent_enabled article.ai_agent_enabled
json.ai_agent_scope article.ai_agent_scope
json.created_at article.created_at
json.updated_at article.updated_at

json.author do
  json.id article.author_id
  json.name article.author&.name
  json.email article.author&.email
end

json.portal do
  json.id article.portal&.id
  json.name article.portal&.name
  json.slug article.portal&.slug
end

if article.category
  json.category do
    json.id article.category.id
    json.name article.category.name
    json.slug article.category.slug
  end
else
  json.category nil
end

json.community_groups article.community_groups do |group|
  json.id group.id
  json.external_id group.external_id
  json.name group.name
  json.account_id group.account_id
end

json.communities article.communities do |community|
  json.id community.id
  json.external_id community.external_id
  json.name community.name
  json.account_id community.account_id
  json.community_group_id community.community_group_id
end
