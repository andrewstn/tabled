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

  test "member can view a published all-member announcement" do
    sign_in_as(users(:member))

    get organization_announcement_path(organizations(:film_society), announcements(:pinned_all_members))

    assert_response :success
    assert_select "h1", announcements(:pinned_all_members).title
    assert_select "h2", "All members"
    assert_select "p", text: /Posted by #{Regexp.escape(users(:owner).name)}/
  end

  test "member cannot view a draft announcement" do
    sign_in_as(users(:member))

    get organization_announcement_path(organizations(:film_society), announcements(:officer_notes))

    assert_response :not_found
  end

  test "owner can view a draft announcement" do
    sign_in_as(users(:owner))

    get organization_announcement_path(organizations(:film_society), announcements(:officer_notes))

    assert_response :success
    assert_select "p", text: "Draft announcement"
    assert_select "h2", "Officers"
  end

  test "owner can create a draft announcement" do
    sign_in_as(users(:owner))

    assert_difference("Announcement.count") do
      post organization_announcements_path(organizations(:film_society)), params: {
        announcement: { title: "Room reminder", body: "Meet in room 214.", audience: "all_members", status: "draft" }
      }
    end

    announcement = Announcement.order(:created_at).last
    assert_predicate announcement, :draft?
    assert_equal users(:owner), announcement.author
    assert_nil announcement.published_at
  end

  test "officer can create a draft announcement" do
    memberships(:film_member).update!(role: :officer)
    sign_in_as(users(:member))

    assert_difference("Announcement.count") do
      post organization_announcements_path(organizations(:film_society)), params: {
        announcement: { title: "Officer note", body: "A note from the officer desk.", audience: "officers", status: "draft" }
      }
    end
  end

  test "member cannot create an announcement" do
    sign_in_as(users(:member))

    assert_no_difference("Announcement.count") do
      post organization_announcements_path(organizations(:film_society)), params: {
        announcement: { title: "Member post", body: "Not authorized.", audience: "all_members", status: "published" }
      }
    end

    assert_response :forbidden
  end

  test "owner can publish a draft and publishing sets published at" do
    announcement = announcements(:officer_notes)
    sign_in_as(users(:owner))

    patch organization_announcement_path(organizations(:film_society), announcement), params: {
      announcement: { title: announcement.title, body: announcement.body, audience: "officers", pinned: "0", status: "published" }
    }

    assert_redirected_to organization_announcement_path(organizations(:film_society), announcement)
    assert_predicate announcement.reload, :published?
    assert_not_nil announcement.published_at
  end

  test "editing a published announcement preserves published at" do
    announcement = announcements(:pinned_all_members)
    published_at = announcement.published_at
    sign_in_as(users(:owner))

    patch organization_announcement_path(organizations(:film_society), announcement), params: {
      announcement: { title: "Updated details", body: announcement.body, audience: "all_members", pinned: "1", status: "draft" }
    }

    assert_predicate announcement.reload, :published?
    assert_equal published_at, announcement.published_at
  end

  test "invalid announcement renders errors" do
    sign_in_as(users(:owner))

    post organization_announcements_path(organizations(:film_society)), params: {
      announcement: { title: "", body: "", audience: "all_members", status: "draft" }
    }

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Title can't be blank/
  end

  test "draft announcement is not emailed when email is selected" do
    sign_in_as(users(:owner))

    assert_no_emails do
      post organization_announcements_path(organizations(:film_society)), params: {
        send_email: "1",
        announcement: { title: "Draft reminder", body: "Still being written.", audience: "all_members", status: "draft" }
      }
    end

    assert_nil Announcement.order(:created_at).last.emailed_at
  end

  test "published announcement can be emailed when selected" do
    sign_in_as(users(:owner))

    assert_emails organizations(:film_society).memberships.count do
      post organization_announcements_path(organizations(:film_society)), params: {
        send_email: "1",
        announcement: { title: "Tonight's room", body: "Meet in the screening room.", audience: "all_members", status: "published" }
      }
    end

    assert_not_nil Announcement.order(:created_at).last.emailed_at
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
