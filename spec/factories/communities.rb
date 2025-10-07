FactoryBot.define do
  factory :community do
    external_id { SecureRandom.uuid }
    name { Faker::Address.community }
    community_group { nil }
    synced_at { Time.current }
  end
end
