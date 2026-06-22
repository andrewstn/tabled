require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  test "organization member can view member directory" do
    sign_in_as(users(:member))

    get organization_members_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Member roster"
    assert_select "tbody tr", count: organizations(:film_society).memberships.count
    assert_select "td", text: users(:owner).email_address
  end

  test "non-member cannot view member directory" do
    sign_in_as(users(:member))

    get organization_members_path(organizations(:garden_club))

    assert_response :not_found
  end

  test "member roster paginates organization members" do
    28.times { |index| create_member(name: "Scale Member #{index}", email: "scale-#{index}@example.test") }
    sign_in_as(users(:member))

    get organization_members_path(organizations(:film_society))

    assert_response :success
    assert_select "tbody tr", count: 25
    assert_select "nav[aria-label='Pagination']", text: /Showing 1–25 of 30/
    assert_select "a", text: "Next"
  end

  test "member roster searches by name and email" do
    target = create_member(name: "Unique Roster Name", email: "special-roster@example.test")
    sign_in_as(users(:member))

    get organization_members_path(organizations(:film_society)), params: { q: "unique roster" }
    assert_select "tbody tr", count: 1
    assert_select "td", text: target.user.email_address

    get organization_members_path(organizations(:film_society)), params: { q: "SPECIAL-ROSTER@EXAMPLE" }
    assert_select "tbody tr", count: 1
    assert_select "th", text: target.user.name
  end

  test "member roster filters by role" do
    create_member(name: "Roster Coordinator", email: "roster-coordinator@example.test", role: :coordinator)
    sign_in_as(users(:member))

    get organization_members_path(organizations(:film_society)), params: { role: "coordinator" }

    assert_select "tbody tr", count: 1
    assert_select ".role-tag", text: "Coordinator"
  end

  test "roster filters never expose another organization" do
    outsider = User.create!(name: "Secret Garden Member", email_address: "secret-garden@example.test", password: "password1234")
    Membership.create!(organization: organizations(:garden_club), user: outsider, role: :member)
    sign_in_as(users(:member))

    get organization_members_path(organizations(:film_society)), params: { q: "Secret Garden" }

    assert_select "p", text: "No members match that search."
    assert_select "td", text: outsider.email_address, count: 0
  end

  test "roster pagination preserves search and role filters" do
    26.times { |index| create_member(name: "Filtered Member #{index}", email: "filtered-#{index}@example.test") }
    sign_in_as(users(:member))

    get organization_members_path(organizations(:film_society)), params: { q: "Filtered", role: "member" }

    assert_select "a", text: "Next" do |links|
      query = Rack::Utils.parse_nested_query(URI.parse(links.first["href"]).query)
      assert_equal "Filtered", query["q"]
      assert_equal "member", query["role"]
      assert_equal "2", query["page"]
    end
  end

  test "organizer can view a member attendance history" do
    sign_in_as(users(:owner))

    get organization_member_path(organizations(:film_society), memberships(:film_member))

    assert_response :success
    assert_select "h2", "Attendance history"
    assert_select "h3", events(:past_planning_table).title
    assert_select ".role-tag", text: "Late"
  end

  test "member can view their own attendance history" do
    sign_in_as(users(:member))

    get organization_member_path(organizations(:film_society), memberships(:film_member))

    assert_response :success
  end

  test "member cannot view another member attendance history" do
    sign_in_as(users(:member))

    get organization_member_path(organizations(:film_society), memberships(:film_owner))

    assert_response :forbidden
  end

  test "owner can update member role" do
    sign_in_as(users(:owner))

    patch organization_member_path(organizations(:film_society), memberships(:film_member)),
      params: { membership: { role: "coordinator" } }

    assert_redirected_to organization_members_path(organizations(:film_society))
    assert memberships(:film_member).reload.coordinator?
  end

  test "member cannot update a role" do
    sign_in_as(users(:member))

    patch organization_member_path(organizations(:film_society), memberships(:film_owner)),
      params: { membership: { role: "member" } }

    assert_response :forbidden
    assert memberships(:film_owner).reload.owner?
  end

  test "officer can update a member to coordinator" do
    memberships(:film_member).update!(role: :officer)
    new_member = User.create!(name: "Casey Nguyen", email_address: "casey@example.com", password: "password1234")
    target = Membership.create!(organization: organizations(:film_society), user: new_member, role: :member)
    sign_in_as(users(:member))

    patch organization_member_path(organizations(:film_society), target),
      params: { membership: { role: "coordinator" } }

    assert_redirected_to organization_members_path(organizations(:film_society))
    assert target.reload.coordinator?
  end

  test "last owner cannot be demoted" do
    sign_in_as(users(:owner))

    patch organization_member_path(organizations(:film_society), memberships(:film_owner)),
      params: { membership: { role: "officer" } }

    assert_redirected_to organization_members_path(organizations(:film_society))
    assert memberships(:film_owner).reload.owner?
  end

  test "owner can remove a member" do
    sign_in_as(users(:owner))

    assert_difference("Membership.count", -1) do
      delete organization_member_path(organizations(:film_society), memberships(:film_member))
    end

    assert_redirected_to organization_members_path(organizations(:film_society))
  end

  test "officer can remove a member" do
    memberships(:film_member).update!(role: :officer)
    new_member = User.create!(name: "Riley Chen", email_address: "riley@example.com", password: "password1234")
    target = Membership.create!(organization: organizations(:film_society), user: new_member, role: :member)
    sign_in_as(users(:member))

    assert_difference("Membership.count", -1) do
      delete organization_member_path(organizations(:film_society), target)
    end
  end

  test "member cannot remove another member" do
    sign_in_as(users(:member))

    assert_no_difference("Membership.count") do
      delete organization_member_path(organizations(:film_society), memberships(:film_owner))
    end

    assert_response :forbidden
  end

  test "non-member cannot remove an organization member" do
    target = Membership.create!(organization: organizations(:garden_club), user: users(:owner), role: :owner)
    sign_in_as(users(:member))

    assert_no_difference("Membership.count") do
      delete organization_member_path(organizations(:garden_club), target)
    end

    assert_response :not_found
  end

  test "last owner cannot be removed" do
    sign_in_as(users(:owner))

    assert_no_difference("Membership.count") do
      delete organization_member_path(organizations(:film_society), memberships(:film_owner))
    end

    assert_redirected_to organization_members_path(organizations(:film_society))
    assert memberships(:film_owner).reload.persisted?
  end

  private

  def create_member(name:, email:, role: :member)
    user = User.create!(name: name, email_address: email, password: "password1234")
    Membership.create!(organization: organizations(:film_society), user: user, role: role)
  end

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
