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

    patch organization_path(organizations(:film_society)), params: {
      organization: {
        name: "Buckeye Cinema Society",
        contact_email: "cinema@example.test",
        website_url: "https://cinema.example.test",
        meeting_note: "Student Union screening room",
        current_semester_label: "Fall 2026"
      }
    }
    assert_redirected_to organization_path(organizations(:film_society))
    assert_equal "Buckeye Cinema Society", organizations(:film_society).reload.name
    assert_equal "cinema@example.test", organizations(:film_society).contact_email
    assert_equal "https://cinema.example.test", organizations(:film_society).website_url
    assert_equal "Student Union screening room", organizations(:film_society).meeting_note
    assert_equal "Fall 2026", organizations(:film_society).current_semester_label
  end

  test "organization settings show slug as read only" do
    sign_in_as(users(:owner))

    get edit_organization_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Organization settings"
    assert_select "code", organizations(:film_society).slug
    assert_select "input[name='organization[slug]']", count: 0
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
