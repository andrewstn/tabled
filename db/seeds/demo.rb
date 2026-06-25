demo_users = [
  { name: "Avery Thompson", email_address: "demo-owner@example.test" },
  { name: "Maya Patel", email_address: "maya.member@example.test" },
  { name: "Theo Brooks", email_address: "theo.member@example.test" },
  { name: "Nina Alvarez", email_address: "nina.member@example.test" }
].to_h do |attributes|
  user = User.find_or_initialize_by(email_address: attributes[:email_address]).tap do |user|
    user.name = attributes[:name]
    user.password = "tabled-demo-password"
    user.demo_account = true
    user.save!
  end
  [ attributes[:email_address], user ]
end

organization = Organization.find_or_initialize_by(slug: "buckeye-film-society")
organization.update!(
  name: "Buckeye Film Society",
  description: "A campus film society for watching, discussing, and making films together all semester.",
  contact_email: "film-society@example.test",
  website_url: "https://film-society.example.test",
  meeting_note: "Student Union screening room on First Fridays",
  current_semester_label: "Fall 2026"
)

legacy_demo_emails = [
  "prospective.member@example.com",
  "new.officer@example.com"
]

organization.memberships
  .joins(:user)
  .where(users: { email_address: legacy_demo_emails })
  .or(
    organization.memberships
      .joins(:user)
      .where("users.email_address ~ ?", '^[^.@]+\.[^.@]+\.[0-9]{3}@example\.edu$')
  )
  .or(
    organization.memberships
      .joins(:user)
      .where("users.email_address LIKE ?", "film.member.%@example.test")
  )
  .destroy_all

organization.invitations
  .where("lower(email) IN (?)", legacy_demo_emails)
  .destroy_all

roles_by_email = {
  "demo-owner@example.test" => :owner,
  "maya.member@example.test" => :officer,
  "theo.member@example.test" => :coordinator,
  "nina.member@example.test" => :member
}

roles_by_email.each do |email_address, role|
  membership = Membership.find_or_initialize_by(
    user: demo_users.fetch(email_address),
    organization: organization
  )
  membership.update!(role: role)
end

Membership.find_by!(organization: organization, user: demo_users.fetch("nina.member@example.test")).update!(
  announcement_emails_enabled: false,
  event_reminder_emails_enabled: true,
  recruitment_emails_enabled: false
)

roster_people = [
  { name: "Jordan Lee", email_address: "jordan.lee@example.edu" },
  { name: "Priya Shah", email_address: "priya.shah@example.edu" },
  { name: "Marcus Williams", email_address: "marcus.williams@example.edu" },
  { name: "Ella Martinez", email_address: "ella.martinez@example.edu" },
  { name: "Samira Hassan", email_address: "samira.hassan@example.edu" },
  { name: "Owen Gallagher", email_address: "owen.gallagher@example.edu" },
  { name: "Leah Kim", email_address: "leah.kim@example.edu" },
  { name: "Diego Ramirez", email_address: "diego.ramirez@example.edu" }
]

scale_memberships = roster_people.each_with_index.map do |attributes, index|
  user = User.find_or_initialize_by(email_address: attributes.fetch(:email_address))
  user.name = attributes.fetch(:name)
  user.password = "tabled-demo-password"
  user.demo_account = true
  user.save!

  organization.memberships.find_or_initialize_by(user: user).tap do |membership|
    membership.role = if index == 0
      :owner
    elsif index.in?([ 6, 18 ])
      :coordinator
    else
      :member
    end
    membership.announcement_emails_enabled = index % 7 != 0
    membership.event_reminder_emails_enabled = index % 5 != 0
    membership.recruitment_emails_enabled = index % 6 != 0
    membership.save!
  end
end

pending_invitations = {
  "camille.bennett@example.edu" => :member,
  "riley.nguyen@example.edu" => :officer
}

pending_invitations.each do |email_address, role|
  invitation = organization.invitations.unresolved
    .where("lower(email) = ?", email_address)
    .first_or_initialize
  invitation.assign_attributes(
    invited_by: demo_users.fetch("demo-owner@example.test"),
    email: email_address,
    role: role,
    expires_at: 14.days.from_now
  )
  invitation.save!
end

event_attributes = {
  "First Friday Film Night" => {
    description: "Bring a favorite short film and something small to share if you can.",
    location: "Student Union screening room",
    starts_at: 5.days.from_now.change(hour: 19, min: 0),
    ends_at: 5.days.from_now.change(hour: 21, min: 0),
    capacity: 24,
    rsvp_deadline: 4.days.from_now.change(hour: 18, min: 0)
  },
  "Camera Workshop" => {
    description: "A hands-on afternoon with the club cameras. No previous experience needed.",
    location: "Media lab 204",
    starts_at: 12.days.from_now.change(hour: 15, min: 30),
    ends_at: 12.days.from_now.change(hour: 17, min: 0),
    capacity: 12,
    rsvp_deadline: 10.days.from_now.change(hour: 20, min: 0)
  },
  "Short Film Planning Table" => {
    description: "A working session to choose crews and sketch the next short film.",
    location: "Library group room 3",
    starts_at: 8.days.ago.change(hour: 18, min: 0),
    ends_at: 8.days.ago.change(hour: 19, min: 30)
  },
  "End-of-Semester Screening" => {
    description: "The semester wrap-up screening for members, friends, and collaborators.",
    location: "Hale Hall auditorium",
    starts_at: 22.days.ago.change(hour: 19, min: 0),
    ends_at: 22.days.ago.change(hour: 21, min: 30)
  }
}

events = event_attributes.to_h do |title, attributes|
  event = organization.events.find_or_initialize_by(title: title)
  event.update!(attributes.merge(created_by: demo_users.fetch("demo-owner@example.test")))
  [ title, event ]
end

rsvp_statuses = {
  "First Friday Film Night" => {
    "demo-owner@example.test" => :attending,
    "maya.member@example.test" => :attending,
    "theo.member@example.test" => :maybe,
    "nina.member@example.test" => :not_attending
  },
  "Camera Workshop" => {
    "demo-owner@example.test" => :attending,
    "maya.member@example.test" => :maybe,
    "nina.member@example.test" => :attending
  },
  "Short Film Planning Table" => {
    "demo-owner@example.test" => :attending,
    "maya.member@example.test" => :attending,
    "theo.member@example.test" => :attending
  },
  "End-of-Semester Screening" => {
    "demo-owner@example.test" => :attending,
    "maya.member@example.test" => :attending,
    "theo.member@example.test" => :maybe,
    "nina.member@example.test" => :attending
  }
}

rsvp_statuses.each do |event_title, statuses_by_email|
  statuses_by_email.each do |email_address, status|
    membership = Membership.find_by!(organization: organization, user: demo_users.fetch(email_address))
    events.fetch(event_title).rsvps.find_or_initialize_by(membership: membership).update!(status: status)
  end
end

planning_event = events.fetch("Short Film Planning Table")
unless planning_event.check_in_code_digest?
  planning_event.regenerate_check_in_code
end
planning_event.update!(
  check_in_opens_at: planning_event.starts_at - 15.minutes,
  check_in_closes_at: planning_event.ends_at + 15.minutes
)

attendance_statuses = {
  "demo-owner@example.test" => { status: :present, minutes_after_start: 0, note: "Opened the room and set out the sign-in sheet." },
  "maya.member@example.test" => { status: :present, minutes_after_start: 2 },
  "theo.member@example.test" => { status: :late, minutes_after_start: 14 },
  "nina.member@example.test" => { status: :excused }
}

attendance_statuses.each do |email_address, attributes|
  membership = Membership.find_by!(organization: organization, user: demo_users.fetch(email_address))
  record = planning_event.attendance_records.find_or_initialize_by(membership: membership)
  checked_in_at = if attributes[:minutes_after_start]
    planning_event.starts_at + attributes[:minutes_after_start].minutes
  end
  record.update!(
    status: attributes.fetch(:status),
    checked_in_at: checked_in_at,
    marked_by: demo_users.fetch("demo-owner@example.test"),
    note: attributes[:note]
  )
end

scale_memberships.each_with_index do |membership, index|
  unless (index % 4) == 3
    rsvp_status = %i[attending maybe not_attending][index % 3]
    planning_event.rsvps.find_or_initialize_by(membership: membership).update!(status: rsvp_status)
  end

  next if (index % 5) == 4

  attendance_status = %i[present late excused absent][index % 4]
  planning_event.attendance_records.find_or_initialize_by(membership: membership).update!(
    status: attendance_status,
    checked_in_at: attendance_status.in?(%i[present late]) ? planning_event.starts_at + index.minutes : nil,
    marked_by: demo_users.fetch("demo-owner@example.test")
  )
end

announcement_attributes = {
  "First Friday Film Night details" => {
    body: "Meet in the Student Union screening room a few minutes before seven. Bring a favorite short film and something small to share if you can.",
    audience: :all_members,
    status: :published,
    pinned: true,
    published_at: 2.days.ago
  },
  "Camera Workshop sign-ups" => {
    body: "Camera Workshop has a few spots left. Add your RSVP if you want to attend.",
    audience: :all_members,
    status: :published,
    pinned: false,
    published_at: 1.day.ago
  },
  "Officer planning notes" => {
    body: "Draft the next meeting agenda and confirm who can open the screening room.",
    audience: :officers,
    status: :draft,
    pinned: false
  },
  "Short Film Planning follow-up" => {
    body: "Thanks for helping shape the next short film. Crew notes are ready for anyone who RSVP’d.",
    audience: :event_rsvps,
    target_event: planning_event,
    status: :published,
    pinned: false,
    published_at: 6.hours.ago
  },
  "Checked-in crew notes" => {
    body: "A few notes for members who checked in at the planning session.",
    audience: :event_attendees,
    target_event: planning_event,
    status: :published,
    pinned: false,
    published_at: 4.hours.ago
  }
}

announcement_attributes.each do |title, attributes|
  announcement = organization.announcements.find_or_initialize_by(title: title)
  announcement.update!(attributes.merge(author: demo_users.fetch("demo-owner@example.test")))
end

delivered_announcement = organization.announcements.find_by!(title: "First Friday Film Night details")
delivered_announcement.recipient_memberships.find_each do |membership|
  delivery = delivered_announcement.announcement_deliveries.find_or_initialize_by(membership: membership)
  if membership.announcement_emails_enabled?
    delivery.update!(
      user: membership.user,
      email: membership.user.email_address,
      status: :sent,
      skipped_reason: nil,
      sent_at: 2.hours.ago
    )
  else
    delivery.update!(
      user: membership.user,
      email: membership.user.email_address,
      status: :skipped,
      skipped_reason: "announcement_emails_disabled",
      sent_at: nil
    )
  end
end
delivered_announcement.update!(emailed_at: 2.hours.ago)

active_join_link = organization.organization_join_links.find_or_initialize_by(label: "Autumn Involvement Fair")
active_join_link.update!(
  created_by: demo_users.fetch("demo-owner@example.test"),
  role: :member,
  active: true,
  expires_at: 90.days.from_now,
  max_uses: 100
)

expired_join_link = organization.organization_join_links.find_or_initialize_by(label: "General recruitment link — closed")
expired_join_link.update!(
  created_by: demo_users.fetch("demo-owner@example.test"),
  role: :member,
  active: false,
  expires_at: 1.day.ago,
  max_uses: nil
)

archived_organization = Organization.find_or_initialize_by(slug: "archived-film-committee")
archived_organization.update!(
  name: "Archived Film Committee",
  description: "A closed demo workspace kept for historical records.",
  contact_email: "archived-film@example.test",
  website_url: "https://archived-film.example.test",
  meeting_note: "Archived after last semester",
  current_semester_label: "Spring 2026",
  archived_at: 30.days.ago
)
archived_membership = archived_organization.memberships.find_or_initialize_by(user: demo_users.fetch("demo-owner@example.test"))
archived_membership.update!(role: :owner)

organization.activity_log_entries.where("metadata @> ?", { demo_seed: true }.to_json).destroy_all

activity_entries = [
  {
    actor: demo_users.fetch("demo-owner@example.test"),
    action: "settings.updated",
    subject: organization,
    summary: "Avery updated organization settings.",
    occurred_at: 2.days.ago,
    metadata: { changed_fields: %w[meeting_note current_semester_label] }
  },
  {
    actor: demo_users.fetch("maya.member@example.test"),
    action: "announcement.published",
    subject: organization.announcements.find_by!(title: "Camera Workshop sign-ups"),
    summary: "Maya published Camera Workshop sign-ups.",
    occurred_at: 1.day.ago,
    metadata: { title: "Camera Workshop sign-ups", audience: "all_members" }
  },
  {
    actor: demo_users.fetch("demo-owner@example.test"),
    action: "announcement.emailed",
    subject: delivered_announcement,
    summary: "Avery emailed First Friday Film Night details.",
    occurred_at: 2.hours.ago,
    metadata: {
      title: delivered_announcement.title,
      sent_count: delivered_announcement.announcement_deliveries.sent.count,
      skipped_count: delivered_announcement.announcement_deliveries.skipped.count
    }
  },
  {
    actor: demo_users.fetch("theo.member@example.test"),
    action: "rsvp.changed",
    subject: events.fetch("First Friday Film Night").rsvps.find_by!(membership: Membership.find_by!(organization: organization, user: demo_users.fetch("theo.member@example.test"))),
    summary: "Theo RSVP’d maybe for First Friday Film Night.",
    occurred_at: 18.hours.ago,
    metadata: { event_title: "First Friday Film Night", status: "maybe" }
  },
  {
    actor: demo_users.fetch("demo-owner@example.test"),
    action: "attendance.marked",
    subject: planning_event.attendance_records.find_by!(membership: Membership.find_by!(organization: organization, user: demo_users.fetch("nina.member@example.test"))),
    summary: "Avery marked Nina Alvarez excused for Short Film Planning Table.",
    occurred_at: 8.days.ago + 2.hours,
    metadata: { event_title: planning_event.title, member_name: "Nina Alvarez", status: "excused" }
  },
  {
    actor: demo_users.fetch("demo-owner@example.test"),
    action: "check_in.opened",
    subject: planning_event,
    summary: "Avery opened check-in for Short Film Planning Table.",
    occurred_at: planning_event.check_in_opens_at,
    metadata: { event_title: planning_event.title, duration_minutes: 120 }
  },
  {
    actor: demo_users.fetch("maya.member@example.test"),
    action: "member.role_changed",
    subject: Membership.find_by!(organization: organization, user: demo_users.fetch("theo.member@example.test")),
    summary: "Maya changed Theo Brooks from member to coordinator.",
    occurred_at: 3.days.ago,
    metadata: { from_role: "member", to_role: "coordinator" }
  },
  {
    actor: demo_users.fetch("demo-owner@example.test"),
    action: "recruitment_link.created",
    subject: active_join_link,
    summary: "Avery created the Autumn Involvement Fair recruitment link.",
    occurred_at: 4.days.ago,
    metadata: { label: active_join_link.label, role: "member", max_uses: active_join_link.max_uses }
  },
  {
    actor: demo_users.fetch("demo-owner@example.test"),
    action: "report.exported",
    summary: "Avery exported the participation report.",
    occurred_at: 6.hours.ago,
    metadata: { report: "participation", format: "csv" }
  },
  {
    actor: demo_users.fetch("nina.member@example.test"),
    action: "communication_preferences.updated",
    subject: Membership.find_by!(organization: organization, user: demo_users.fetch("nina.member@example.test")),
    summary: "Nina updated their communication preferences.",
    occurred_at: 5.hours.ago,
    metadata: {}
  }
]

activity_entries.each do |attributes|
  ActivityLog.record!(
    organization: organization,
    actor: attributes[:actor],
    action: attributes[:action],
    subject: attributes[:subject],
    summary: attributes[:summary],
    occurred_at: attributes[:occurred_at],
    metadata: attributes.fetch(:metadata).merge(demo_seed: true)
  )
end

ActivityLog.record!(
  organization: archived_organization,
  actor: demo_users.fetch("demo-owner@example.test"),
  action: "organization.archived",
  subject: archived_organization,
  summary: "Avery archived Archived Film Committee.",
  occurred_at: 30.days.ago,
  metadata: { organization_name: archived_organization.name, demo_seed: true }
)

puts "Seeded Buckeye Film Society with a 12-person roster, report-ready attendance records, communication preferences, settings data, log book activity, and recruitment links."
puts "Sign in as demo-owner@example.test with tabled-demo-password."
