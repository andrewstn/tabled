demo_users = [
  { name: "Avery Thompson", email_address: "demo-owner@example.test" },
  { name: "Maya Patel", email_address: "maya.member@example.test" },
  { name: "Theo Brooks", email_address: "theo.member@example.test" },
  { name: "Nina Alvarez", email_address: "nina.member@example.test" }
].to_h do |attributes|
  user = User.find_or_initialize_by(email_address: attributes[:email_address]).tap do |user|
    user.name = attributes[:name]
    user.password = "tabled-demo-password" if user.new_record?
    user.save!
  end
  [ attributes[:email_address], user ]
end

organization = Organization.find_or_initialize_by(slug: "buckeye-film-society")
organization.update!(
  name: "Buckeye Film Society",
  description: "A campus film society for watching, discussing, and making films together all semester."
)

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

scale_memberships = 28.times.map do |index|
  email_address = format("film.member.%02d@example.test", index + 1)
  user = User.find_or_initialize_by(email_address: email_address)
  user.name = format("Film Society Member %02d", index + 1)
  user.password = "tabled-demo-password" if user.new_record?
  user.save!

  organization.memberships.find_or_initialize_by(user: user).tap do |membership|
    membership.role = index.in?([ 6, 18 ]) ? :coordinator : :member
    membership.save!
  end
end

pending_invitations = {
  "prospective.member@example.com" => :member,
  "new.officer@example.com" => :officer
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
  }
}

announcement_attributes.each do |title, attributes|
  announcement = organization.announcements.find_or_initialize_by(title: title)
  announcement.update!(attributes.merge(author: demo_users.fetch("demo-owner@example.test")))
end

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

puts "Seeded Buckeye Film Society with a 32-person roster, report-ready attendance records, and recruitment links."
puts "Sign in as demo-owner@example.test with tabled-demo-password."
