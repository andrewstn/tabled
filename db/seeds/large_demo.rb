if Rails.env.production? && ENV["ALLOW_LARGE_DEMO_SEED"] != "true"
  raise "Large demo seed is disabled in production. Set ALLOW_LARGE_DEMO_SEED=true only if you intentionally want large demo data there."
end

PASSWORD = "tabled-demo-password"

FIRST_NAMES = %w[
  Alex Avery Bailey Cameron Casey Dakota Drew Eden Emery Finley Harper Hayden
  Jamie Jordan Jules Kai Kennedy Logan Morgan Parker Quinn Reese Riley Rowan
  Sage Sam Skyler Taylor Tessa Theo Zion
].freeze

LAST_NAMES = %w[
  Adams Alvarez Bennett Brooks Carter Chen Davis Diaz Edwards Ellis Foster
  Garcia Green Hayes Hughes Johnson Kim Lee Lewis Martinez Morgan Nguyen Patel
  Reed Rivera Roberts Singh Thompson Turner Walker Young
].freeze

def large_demo_user(index)
  email = format("large-demo-%03d@example.com", index)
  user = User.find_or_initialize_by(email_address: email)
  user.name = "#{FIRST_NAMES[index % FIRST_NAMES.size]} #{LAST_NAMES[(index / FIRST_NAMES.size) % LAST_NAMES.size]}"
  user.password = PASSWORD if user.new_record?
  user.save!
  user
end

def large_demo_organization(name:, slug:, index:, archived: false)
  organization = Organization.find_or_initialize_by(slug: slug)
  organization.update!(
    name: name,
    description: "#{name} keeps its semester roster, gatherings, attendance, and announcements in Tabled.",
    contact_email: "#{slug}@example.com",
    website_url: "https://#{slug}.example.com",
    meeting_note: [ "Student Union room #{200 + index}", "Library collaboration room #{index}", "Campus center table #{index}" ][index % 3],
    current_semester_label: "Fall 2026",
    archived_at: archived ? 45.days.ago : nil
  )
  organization
end

def large_demo_membership(organization:, user:, role:, index:)
  membership = organization.memberships.find_or_initialize_by(user: user)
  membership.role = role
  membership.announcement_emails_enabled = index % 9 != 0
  membership.event_reminder_emails_enabled = index % 7 != 0
  membership.recruitment_emails_enabled = index % 11 != 0
  membership.save!
  membership
end

def large_demo_event(organization:, creator:, title:, starts_at:, index:)
  event = organization.events.find_or_initialize_by(title: title)
  event.update!(
    created_by: creator,
    description: "Demo gathering ##{index + 1} for #{organization.name}.",
    location: [ "Student Union screening room", "Media lab 204", "Library group room", "Campus center lounge" ][index % 4],
    starts_at: starts_at,
    ends_at: starts_at + [ 60, 75, 90, 120 ][index % 4].minutes,
    capacity: index % 3 == 0 ? 30 + (index % 5) * 5 : nil,
    rsvp_deadline: starts_at.future? ? starts_at - 1.day : nil
  )
  event
end

organizations = [
  [ "Buckeye Film Society", "buckeye-film-society", false ],
  [ "Campus Volunteer Board", "campus-volunteer-board", false ],
  [ "Residence Hall Council", "residence-hall-council", false ],
  [ "Software Builders Club", "software-builders-club", false ],
  [ "Community Garden Club", "community-garden-club", false ],
  [ "Undergraduate Film Collective", "undergraduate-film-collective", false ],
  [ "Student Design Studio", "student-design-studio", true ]
].each_with_index.to_h do |(name, slug, archived), index|
  [ slug, large_demo_organization(name: name, slug: slug, index: index, archived: archived) ]
end

users = 260.times.map { |index| large_demo_user(index + 1) }
main_organization = organizations.fetch("buckeye-film-society")

memberships_by_organization = {}

organizations.values.each_with_index do |organization, org_index|
  member_count = organization == main_organization ? 125 : 28
  offset = org_index * 25
  memberships = member_count.times.map do |index|
    user = users[(offset + index) % users.size]
    role = if index.zero?
      :owner
    elsif index.in?([ 1, 2, 18 ])
      :officer
    elsif index.in?([ 3, 12, 24 ])
      :coordinator
    else
      :member
    end
    large_demo_membership(organization: organization, user: user, role: role, index: index)
  end
  memberships_by_organization[organization.slug] = memberships
end

organizations.values.each do |organization|
  owner = memberships_by_organization.fetch(organization.slug).find(&:owner?).user
  organization.activity_log_entries.where("metadata @> ?", { large_demo_seed: true }.to_json).destroy_all

  4.times do |index|
    email = "#{organization.slug}-invite-#{index + 1}@example.com"
    invitation = organization.invitations.unresolved.where("lower(email) = ?", email).first_or_initialize
    invitation.assign_attributes(
      invited_by: owner,
      email: email,
      role: index == 1 ? :coordinator : :member,
      expires_at: (10 + index).days.from_now
    )
    invitation.save!
  end

  3.times do |index|
    join_link = organization.organization_join_links.find_or_initialize_by(label: [ "Fall involvement fair", "Poster QR code", "Dorm floor interest list" ][index])
    join_link.update!(
      created_by: owner,
      role: :member,
      active: index != 2,
      expires_at: index == 2 ? 2.days.ago : 60.days.from_now,
      max_uses: index.zero? ? 150 : nil,
      uses_count: index * 4
    )
  end
end

events_by_organization = {}

organizations.values.each_with_index do |organization, org_index|
  creator = memberships_by_organization.fetch(organization.slug).find(&:owner?).user
  event_count = organization == main_organization ? 32 : 9
  events = event_count.times.map do |index|
    starts_at = if index < (event_count * 0.65)
      (event_count - index).days.ago.change(hour: 18 + (index % 3), min: 0)
    else
      (index - (event_count * 0.65).floor + 2).days.from_now.change(hour: 17 + (index % 4), min: 30)
    end
    title = [
      "Planning Table", "Workshop", "General Meeting", "Screening Night",
      "Volunteer Shift", "Officer Huddle", "Project Studio", "Community Table"
    ][index % 8]
    large_demo_event(
      organization: organization,
      creator: creator,
      title: "#{title} #{index + 1}",
      starts_at: starts_at,
      index: index + org_index
    )
  end
  events_by_organization[organization.slug] = events
end

events_by_organization.each do |slug, events|
  organization = organizations.fetch(slug)
  memberships = memberships_by_organization.fetch(slug)
  owner = memberships.find(&:owner?).user

  events.each_with_index do |event, event_index|
    memberships.each_with_index do |membership, member_index|
      next if member_index > 40 && event_index % 2 == 1
      next if (member_index + event_index) % 5 == 0

      rsvp_status = Rsvp::STATUSES[(member_index + event_index) % Rsvp::STATUSES.size]
      event.rsvps.find_or_initialize_by(membership: membership).update!(status: rsvp_status)

      next unless event.past?
      next if event_index % 7 == 0
      next if (member_index + event_index) % 6 == 0

      attendance_status = AttendanceRecord::STATUSES[(member_index + event_index) % AttendanceRecord::STATUSES.size]
      event.attendance_records.find_or_initialize_by(membership: membership).update!(
        status: attendance_status,
        checked_in_at: attendance_status.in?(%w[present late]) ? event.starts_at + (member_index % 25).minutes : nil,
        marked_by: owner,
        note: member_index % 17 == 0 ? "Large demo note for filtering and review." : nil
      )
    end

    next unless event.past? && event_index % 6 == 1

    event.regenerate_check_in_code unless event.check_in_code_digest?
    event.update!(
      check_in_opens_at: event.starts_at - 15.minutes,
      check_in_closes_at: event.ends_at + 15.minutes
    )
  end
end

organizations.values.each do |organization|
  memberships = memberships_by_organization.fetch(organization.slug)
  author = memberships.find { |membership| membership.owner? || membership.officer? }.user
  target_events = events_by_organization.fetch(organization.slug).select(&:past?)

  18.times do |index|
    audience = Announcement::AUDIENCES[index % Announcement::AUDIENCES.size]
    audience = "all_members" if target_events.empty? && Announcement::EVENT_AUDIENCES.include?(audience)
    announcement = organization.announcements.find_or_initialize_by(title: "Large demo bulletin #{index + 1}")
    announcement.update!(
      author: author,
      body: "A practical large-demo announcement for #{organization.name}.",
      audience: audience,
      target_event: Announcement::EVENT_AUDIENCES.include?(audience) ? target_events[index % target_events.size] : nil,
      status: index % 6 == 0 ? :draft : :published,
      pinned: index.zero?,
      published_at: index % 6 == 0 ? nil : (index + 1).hours.ago
    )
  end
end

organizations.values.each do |organization|
  memberships = memberships_by_organization.fetch(organization.slug)
  owner = memberships.find(&:owner?).user
  events = events_by_organization.fetch(organization.slug)
  announcement = organization.announcements.published.first
  event = events.first
  attendance_record = event&.attendance_records&.first

  [
    [ "member.joined", "#{memberships.last.user.name} joined #{organization.name}.", memberships.last ],
    [ "invitation.created", "#{owner.name} invited a prospective member.", organization.invitations.pending.first ],
    [ "recruitment_link.created", "#{owner.name} created a recruitment link.", organization.organization_join_links.first ],
    [ "event.created", "#{owner.name} created #{event&.title}.", event ],
    [ "rsvp.changed", "#{memberships.second.user.name} updated an RSVP.", event&.rsvps&.first ],
    [ "attendance.marked", "#{owner.name} marked attendance for #{event&.title}.", attendance_record ],
    [ "announcement.published", "#{owner.name} published #{announcement&.title}.", announcement ],
    [ "report.exported", "#{owner.name} exported a semester report.", nil ],
    [ "settings.updated", "#{owner.name} updated organization settings.", organization ]
  ].compact.each_with_index do |(action, summary, subject), index|
    ActivityLog.record!(
      organization: organization,
      actor: owner,
      action: action,
      subject: subject,
      summary: summary,
      occurred_at: (index + 1).hours.ago,
      metadata: { large_demo_seed: true }
    )
  end
end

puts "Seeded large demo data: #{Organization.where(slug: organizations.keys).count} organizations, #{users.size} users, #{main_organization.memberships.count} Buckeye Film Society members."
puts "Sign in with any large-demo user, for example large-demo-001@example.com / #{PASSWORD}."
