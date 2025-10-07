FactoryBot.define do
  factory :community_group do
    external_id { SecureRandom.uuid }
    name { Faker::Company.name }
    synced_at { Time.current }
  end
end
