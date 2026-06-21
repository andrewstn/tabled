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
    assert_select "p", text: /members around the table/, count: 0
    assert_select ".member-row .role-tag", count: 2
    assert_select "h3", text: events(:upcoming_film_night).title
    assert_select ".event-row .role-tag", text: "Maybe"
    assert_select "p", text: /The board is clear/
    assert_select "p", text: "Nothing needs follow-up right now."
    assert_select "p", text: "No notes in the log book yet."
    assert_select "a[href=?]", organization_members_path(organizations(:film_society)), text: /Member roster/
    assert_select "a[href=?]", organization_events_path(organizations(:film_society)), text: "Gatherings"
    assert_select "a[href=?]", new_organization_invitation_path(organizations(:film_society)), count: 0
  end

  test "owner sees member onboarding actions backed by pending invitations" do
    sign_in_as(users(:owner))

    get organization_path(organizations(:film_society))

    assert_select "a[href=?]", new_organization_invitation_path(organizations(:film_society)), text: "Invite member"
    assert_select "a[href=?]", organization_invitations_path(organizations(:film_society)), text: "Pending invitations (1)"
    assert_select "a[href=?]", new_organization_event_path(organizations(:film_society)), text: "Add gathering"
  end

  test "dashboard shows the gathering empty state from real data" do
    organizations(:film_society).events.destroy_all
    sign_in_as(users(:member))

    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select "p", text: "No gatherings yet."
    assert_select "h3", text: "First Friday Film Night", count: 0
  end

  test "navigation lets a user switch organizations" do
    Membership.create!(user: users(:owner), organization: organizations(:garden_club), role: :officer)
    sign_in_as(users(:owner))

    get organization_path(organizations(:film_society))

    assert_select "nav[aria-label='Your organizations']" do
      assert_select "a[href=?]", organization_path(organizations(:film_society))
      assert_select "a[href=?]", organization_path(organizations(:garden_club))
      assert_select "a[aria-current='page'][href=?]", organization_path(organizations(:film_society))
    end
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
