json.articles do
  json.array! @articles do |article|
    json.partial! 'article', article: article
  end
end

json.meta do
  json.total @total
  json.limit @limit
  json.offset @offset
  json.has_more @has_more
end
