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

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
