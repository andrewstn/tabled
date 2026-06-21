require "test_helper"

class OrganizationsDashboardTest < ActionDispatch::IntegrationTest
  test "a member sees the organization dashboard and their role" do
    sign_in_as(users(:member))

    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", organizations(:film_society).name
    assert_select "span", text: "Member"
    assert_select "h2", text: "Around the table"
    assert_select "h2", text: "Upcoming gatherings"
    assert_select "h2", text: "Recent roll call"
    assert_select "h2", text: "Bulletin"
    assert_select "h2", text: "What needs attention"
    assert_select "p", text: "No gatherings yet."
    assert_select "p", text: /The board is clear/
    assert_select "p", text: "Nothing needs follow-up right now."
    assert_select "p", text: "No notes in the log book yet."
  end

  test "navigation lets a user switch organizations" do
    Membership.create!(user: users(:owner), organization: organizations(:garden_club), role: :officer)
    sign_in_as(users(:owner))

    get organization_path(organizations(:film_society))

    assert_select "nav[aria-label='Your organizations']" do
      assert_select "a[href=?]", organization_path(organizations(:film_society))
      assert_select "a[href=?]", organization_path(organizations(:garden_club))
    end
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
