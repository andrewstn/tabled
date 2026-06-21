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
  description: "A campus table for watching, discussing, and making films together all semester."
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

puts "Seeded Buckeye Film Society with four members and two pending invitations."
puts "Sign in as demo-owner@example.test with tabled-demo-password."
