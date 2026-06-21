require "test_helper"

class OrganizationAuthorizationTest < ActionDispatch::IntegrationTest
  test "a user cannot view an organization they do not belong to" do
    sign_in_as(users(:member))

    get organization_path(organizations(:garden_club))

    assert_response :not_found
  end

  test "a member cannot access organization settings" do
    sign_in_as(users(:member))

    get edit_organization_path(organizations(:film_society))

    assert_response :forbidden
  end

  test "an officer can access organization settings" do
    membership = memberships(:film_member)
    membership.update!(role: :officer)
    sign_in_as(users(:member))

    get edit_organization_path(organizations(:film_society))

    assert_response :success
  end

  test "an owner can access organization settings and update details" do
    sign_in_as(users(:owner))

    get edit_organization_path(organizations(:film_society))
    assert_response :success

    patch organization_path(organizations(:film_society)), params: { organization: { name: "Buckeye Cinema Society" } }
    assert_redirected_to organization_path(organizations(:film_society))
    assert_equal "Buckeye Cinema Society", organizations(:film_society).reload.name
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
