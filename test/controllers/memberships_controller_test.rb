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

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
