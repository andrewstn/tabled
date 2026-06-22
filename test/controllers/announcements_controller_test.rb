require "test_helper"

class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  test "member sees published all-member announcements in pinned order" do
    sign_in_as(users(:member))

    get organization_announcements_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Bulletin"
    assert_select "#published-bulletin article:first-child h3", announcements(:pinned_all_members).title
    assert_select "h3", announcements(:recent_all_members).title
    assert_select "h3", { text: announcements(:officer_notes).title, count: 0 }
    assert_select "h2", { text: "Drafts", count: 0 }
  end

  test "owner sees drafts" do
    sign_in_as(users(:owner))

    get organization_announcements_path(organizations(:film_society))

    assert_response :success
    assert_select "h2", "Drafts"
    assert_select "h3", announcements(:officer_notes).title
  end

  test "non-member cannot view bulletin" do
    sign_in_as(users(:member))

    get organization_announcements_path(organizations(:garden_club))

    assert_response :not_found
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
