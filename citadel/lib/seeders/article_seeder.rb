# frozen_string_literal: true

module Seeders::ArticleSeeder
  def self.seed_articles
    account = Account.find_by!(name: 'Acme Inc')
    user = User.find_by!(email: 'john@acme.inc')

    # Use existing portal from seed
    portal = Portal.find_by!(slug: 'test-portal', account: account)

    # Use existing category from seed
    category = Category.find_by!(portal: portal, slug: 'test-category')

    # Get community groups and communities
    downtown_group = CommunityGroup.find_by(name: 'Downtown Properties')
    oak_tower = Community.find_by(name: 'Oak Tower')

    # 1. Organization-scoped article
    article1 = Article.find_or_initialize_by(slug: 'are-there-any-events-or-social-activities')
    article1.assign_attributes(
      account: account,
      portal: portal,
      author_id: user.id,
      title: '💌 Are there any events or social activities?',
      content: <<~CONTENT,
        Yes! We organize regular community events and social activities for our residents.

        **Monthly Events:**
        - Community dinners (first Friday of each month)
        - Game nights and movie screenings
        - Seasonal celebrations and holiday parties

        **Ongoing Activities:**
        - Book club meetings
        - Fitness classes and yoga sessions
        - Language exchange meetups

        Events are announced via email and posted in common areas. Participation is optional but highly encouraged!

        For specific event schedules or to suggest activities, contact our community manager.
      CONTENT
      description: 'Information about community events and social activities available to residents',
      status: :published,
      category: category,
      ai_agent_enabled: true,
      ai_agent_scope: :organization
    )
    article1.save!

    # 2. Community Group-scoped article (Downtown Properties)
    if downtown_group
      article2 = Article.find_or_initialize_by(slug: 'how-do-i-register-my-residency-in-belgium')
      article2.assign_attributes(
        account: account,
        portal: portal,
        author_id: user.id,
        title: 'How Do I Register My Residency in Belgium',
        content: <<~CONTENT,
          All residents must register with the local municipality (commune/gemeente) within 8 working days of moving in.

          **Required Documents:**
          - Valid passport or national ID
          - Signed lease agreement
          - Proof of address (your lease serves this purpose)
          - Passport-sized photo (may vary by commune)

          **Registration Process:**
          1. Book an appointment with your local commune office online
          2. Bring all required documents to your appointment
          3. An inspector may visit to verify you live at the address
          4. After approval, you'll receive your residence certificate

          **Important Notes:**
          - Brussels has 19 communes - register with the one where your property is located
          - Registration is mandatory and failure to register can result in fines
          - Your landlord should provide all necessary documents
          - EU citizens and non-EU citizens follow the same initial registration process

          **Downtown Properties Locations:**
          - Oak Tower: Register at City of Brussels commune
          - Maple Plaza: Register at City of Brussels commune

          For questions about the registration process, contact your property manager.
        CONTENT
        description: 'Guide to registering your residency in Belgium for downtown properties',
        status: :published,
        category: category,
        ai_agent_enabled: true,
        ai_agent_scope: :community_group
      )
      article2.community_groups = [downtown_group]
      article2.save!
    end

    # 3. Community-scoped article (Oak Tower)
    if oak_tower
      article3 = Article.find_or_initialize_by(slug: 'can-i-park-my-car-at-the-house-for-free')
      article3.assign_attributes(
        account: account,
        portal: portal,
        author_id: user.id,
        title: 'Can I park my car at the house for free',
        content: <<~CONTENT,
          **Oak Tower Parking Information**

          Unfortunately, Oak Tower does not offer free parking. Here are your parking options:

          **On-Site Parking:**
          - Underground parking garage available
          - Monthly rate: €150/month
          - Subject to availability - contact building management to reserve a spot
          - Access card required (€50 deposit)

          **Street Parking:**
          - Paid street parking available in surrounding area
          - Mon-Sat: 9am-7pm (€2.50/hour)
          - Free parking: Sundays and after 7pm
          - Resident parking permits available from the City of Brussels commune (€150/year)

          **Alternative Options:**
          - Public parking garage on Rue de la Loi (5 min walk): €120/month
          - Consider car-sharing services like Cambio or Poppy for occasional use

          To reserve an underground parking spot, contact the building manager at oaktower@acme.inc or call the front desk.
        CONTENT
        description: 'Parking options and pricing information for Oak Tower residents',
        status: :published,
        category: category,
        ai_agent_enabled: true,
        ai_agent_scope: :community
      )
      article3.communities = [oak_tower]
      article3.save!
    end

    puts '✅ Articles seeded successfully'
    puts "  - Organization scope: '💌 Are there any events or social activities?'"
    puts "  - Community Group scope: 'How Do I Register My Residency in Belgium'" if downtown_group
    puts "  - Community scope: 'Can I park my car at the house for free'" if oak_tower
  end
end
