require "test_helper"

class OrganizationLeavesControllerTest < ActionDispatch::IntegrationTest
  test "member can leave organization" do
    sign_in_as(users(:member))

    assert_difference("Membership.count", -1) do
      delete organization_leave_path(organizations(:film_society))
    end

    assert_redirected_to root_path
    assert_nil users(:member).memberships.find_by(organization: organizations(:film_society))
  end

  test "last owner cannot leave organization" do
    sign_in_as(users(:owner))

    assert_no_difference("Membership.count") do
      delete organization_leave_path(organizations(:film_society))
    end

    assert_redirected_to organization_path(organizations(:film_society))
    assert_equal "Every organization needs at least one owner", flash[:alert]
  end

  test "owner can leave when another owner remains" do
    memberships(:film_member).update!(role: :owner)
    sign_in_as(users(:owner))

    assert_difference("Membership.count", -1) do
      delete organization_leave_path(organizations(:film_society))
    end

    assert_redirected_to root_path
    assert_predicate memberships(:film_member).reload, :owner?
  end

  test "non-member cannot leave organization" do
    sign_in_as(users(:member))

    delete organization_leave_path(organizations(:garden_club))

    assert_response :not_found
  end

  test "dashboard shows leave organization action" do
    sign_in_as(users(:member))

    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select "h2", "Leave organization"
    assert_select "form[action=?]", organization_leave_path(organizations(:film_society))
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
