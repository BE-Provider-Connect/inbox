namespace :community do
  desc 'Sync communities and community groups from Citadel API'
  task sync: :environment do
    puts 'Starting community sync...'
    stats = CommunitySyncService.new.perform
    puts 'Community sync completed!'
    puts "Community Groups - Created: #{stats[:community_groups][:created]}, Updated: #{stats[:community_groups][:updated]}"
    puts "Communities - Created: #{stats[:communities][:created]}, Updated: #{stats[:communities][:updated]}"
  end
end
