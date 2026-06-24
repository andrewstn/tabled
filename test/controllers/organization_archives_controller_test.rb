require "test_helper"

class OrganizationArchivesControllerTest < ActionDispatch::IntegrationTest
  test "owner can archive organization" do
    sign_in_as(users(:owner))

    assert_difference("ActivityLogEntry.count") do
      patch organization_archive_path(organizations(:film_society))
    end

    assert_redirected_to organization_path(organizations(:film_society))
    assert_predicate organizations(:film_society).reload, :archived?
    assert_equal "organization.archived", ActivityLogEntry.order(:created_at).last.action
  end

  test "non-owner cannot archive organization" do
    memberships(:film_member).update!(role: :officer)
    sign_in_as(users(:member))

    patch organization_archive_path(organizations(:film_society))

    assert_response :forbidden
    assert_not_predicate organizations(:film_society).reload, :archived?
  end

  test "owner can restore organization" do
    organizations(:film_society).archive!
    sign_in_as(users(:owner))

    assert_difference("ActivityLogEntry.count") do
      delete organization_archive_path(organizations(:film_society))
    end

    assert_redirected_to organization_path(organizations(:film_society))
    assert_not_predicate organizations(:film_society).reload, :archived?
    assert_equal "organization.restored", ActivityLogEntry.order(:created_at).last.action
  end

  test "archived organization is hidden from normal organization lists" do
    organizations(:film_society).archive!
    sign_in_as(users(:owner))

    get root_path

    assert_response :success
    assert_select "a[href=?]", organization_path(organizations(:film_society)), count: 0
  end

  test "owner can view archived organization directly" do
    organizations(:film_society).archive!
    sign_in_as(users(:owner))

    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select "p", text: "This organization is archived."
  end

  test "non-member cannot access archived organization data" do
    organizations(:garden_club).archive!
    sign_in_as(users(:member))

    get organization_path(organizations(:garden_club))

    assert_response :not_found
  end

  test "archived organization blocks new events" do
    organizations(:film_society).archive!
    sign_in_as(users(:owner))

    assert_no_difference("Event.count") do
      post organization_events_path(organizations(:film_society)), params: {
        event: { title: "Archived meeting", starts_at: 1.week.from_now }
      }
    end

    assert_redirected_to organization_path(organizations(:film_society))
  end

  test "archived organization blocks new invitations" do
    organizations(:film_society).archive!
    sign_in_as(users(:owner))

    assert_no_difference("Invitation.count") do
      post organization_invitations_path(organizations(:film_society)), params: {
        invitation: { email: "archived@example.test", role: "member" }
      }
    end

    assert_redirected_to organization_path(organizations(:film_society))
  end

  test "archived organization blocks new recruitment links" do
    organizations(:film_society).archive!
    sign_in_as(users(:owner))

    assert_no_difference("OrganizationJoinLink.count") do
      post organization_join_links_path(organizations(:film_society)), params: {
        organization_join_link: { label: "Closed fair" }
      }
    end

    assert_redirected_to organization_path(organizations(:film_society))
  end

  test "archived organization blocks new announcements" do
    organizations(:film_society).archive!
    sign_in_as(users(:owner))

    assert_no_difference("Announcement.count") do
      post organization_announcements_path(organizations(:film_society)), params: {
        announcement: { title: "Closed note", body: "No new activity.", audience: "all_members", status: "published" }
      }
    end

    assert_redirected_to organization_path(organizations(:film_society))
  end

  test "archived organization blocks roster imports" do
    organizations(:film_society).archive!
    sign_in_as(users(:owner))

    post organization_roster_import_path(organizations(:film_society)), params: {
      roster_import: { csv_file: fixture_file_upload("roster_import.csv", "text/csv") }
    }

    assert_redirected_to organization_path(organizations(:film_society))
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
