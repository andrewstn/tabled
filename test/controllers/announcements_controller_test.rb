require "test_helper"

class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  test "member sees published all-member announcements in newest-first order" do
    sign_in_as(users(:member))

    get organization_announcements_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Bulletin"
    assert_select "#published-bulletin article:first-child h3", announcements(:recent_all_members).title
    assert_select "h3", announcements(:pinned_all_members).title
    assert_select "h3", announcements(:recent_all_members).title
    assert_select "h3", { text: announcements(:officer_notes).title, count: 0 }
    assert_select "h2", { text: "Drafts", count: 0 }
  end

  test "member can page through published announcements" do
    7.times do |index|
      organizations(:film_society).announcements.create!(
        author: users(:owner),
        title: "Paged bulletin #{format("%02d", index)}",
        body: "A paged bulletin item.",
        audience: :all_members,
        status: :published,
        published_at: index.minutes.ago
      )
    end
    sign_in_as(users(:member))

    get organization_announcements_path(organizations(:film_society))

    assert_response :success
    assert_select "#published-bulletin article", count: 6
    assert_select "#published-bulletin article:first-child h3", "Paged bulletin 00"
    assert_select "nav[aria-label='Pagination']", text: /Showing 1–6 of 9/
    assert_select "a[href$='#published-announcements']", text: "Next"

    get organization_announcements_path(organizations(:film_society)), params: { page: 2 }

    assert_response :success
    assert_select "#published-bulletin article", count: 3
    assert_select "h3", "Paged bulletin 06"
    assert_select "h3", announcements(:recent_all_members).title
    assert_select "h3", announcements(:pinned_all_members).title
    assert_select "nav[aria-label='Pagination']", text: /Showing 7–9 of 9/
    assert_select "a[href$='#published-announcements']", text: "Previous"
  end

  test "owner sees drafts" do
    sign_in_as(users(:owner))

    get organization_announcements_path(organizations(:film_society))

    assert_response :success
    assert_select "h2", "Drafts"
    assert_select "h3", announcements(:officer_notes).title
    assert_select "a[href=?]", new_organization_announcement_path(organizations(:film_society)), text: "Post announcement"
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

  test "all members announcement is visible to organization members" do
    sign_in_as(users(:member))

    get organization_announcements_path(organizations(:film_society))

    assert_select "h3", announcements(:pinned_all_members).title
  end

  test "officers announcement is visible to organizer roles only" do
    announcement = announcements(:officer_notes)
    announcement.update!(status: :published)
    memberships(:film_member).update!(role: :coordinator)
    sign_in_as(users(:member))

    get organization_announcement_path(organizations(:film_society), announcement)

    assert_response :success
    assert_select "h1", announcement.title
  end

  test "officers announcement is not visible to regular members" do
    announcement = announcements(:officer_notes)
    announcement.update!(status: :published)
    memberships(:film_member).update!(role: :member)
    sign_in_as(users(:member))

    get organization_announcement_path(organizations(:film_society), announcement)

    assert_response :not_found
  end

  test "event rsvps announcement is visible to members with RSVP" do
    announcement = create_targeted_announcement(audience: :event_rsvps, target_event: events(:upcoming_film_night))
    sign_in_as(users(:member))

    get organization_announcement_path(organizations(:film_society), announcement)

    assert_response :success
    assert_select "h2", "Event RSVPs"
  end

  test "event rsvps announcement is not visible to members without RSVP" do
    user = create_user("No RSVP", "no-rsvp@example.test")
    Membership.create!(organization: organizations(:film_society), user: user, role: :member)
    announcement = create_targeted_announcement(audience: :event_rsvps, target_event: events(:upcoming_film_night))
    sign_in_as(user)

    get organization_announcement_path(organizations(:film_society), announcement)

    assert_response :not_found
  end

  test "event attendees announcement is visible to present or late members" do
    announcement = create_targeted_announcement(audience: :event_attendees, target_event: events(:past_planning_table))
    sign_in_as(users(:member))

    get organization_announcement_path(organizations(:film_society), announcement)

    assert_response :success
    assert_select "h2", "Checked-in attendees"
  end

  test "event attendees announcement is not visible to members without present or late attendance" do
    user = create_user("Absent Member", "absent-member@example.test")
    membership = Membership.create!(organization: organizations(:film_society), user: user, role: :member)
    events(:past_planning_table).attendance_records.create!(membership: membership, marked_by: users(:owner), status: :absent)
    announcement = create_targeted_announcement(audience: :event_attendees, target_event: events(:past_planning_table))
    sign_in_as(user)

    get organization_announcement_path(organizations(:film_society), announcement)

    assert_response :not_found
  end

  test "non-member cannot view targeted announcement" do
    announcement = create_targeted_announcement(audience: :event_rsvps, target_event: events(:upcoming_film_night))
    sign_in_as(users(:member))

    get organization_announcement_path(organizations(:garden_club), announcement)

    assert_response :not_found
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

    assert_difference([ "Announcement.count", "ActivityLogEntry.count" ]) do
      post organization_announcements_path(organizations(:film_society)), params: {
        announcement: { title: "Room reminder", body: "Meet in room 214.", audience: "all_members", status: "draft" }
      }
    end

    announcement = Announcement.order(:created_at).last
    assert_predicate announcement, :draft?
    assert_equal users(:owner), announcement.author
    assert_nil announcement.published_at
    assert_equal "announcement.drafted", ActivityLogEntry.order(:created_at).last.action
  end

  test "announcement form shows delivery preview" do
    memberships(:film_member).update!(announcement_emails_enabled: false)
    sign_in_as(users(:owner))

    get new_organization_announcement_path(organizations(:film_society))

    assert_response :success
    assert_select "p", text: "Delivery preview"
    assert_select "p", text: /Visible to 2 members/
    assert_select "p", text: /Email will be sent to 1 member/
    assert_select "p", text: /1 member have announcement emails turned off/
  end

  test "event audience announcement requires target event from form" do
    sign_in_as(users(:owner))

    post organization_announcements_path(organizations(:film_society)), params: {
      announcement: { title: "RSVP note", body: "For RSVPs.", audience: "event_rsvps", target_event_id: "", status: "published" }
    }

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Target event must be selected/
  end

  test "owner can create event targeted announcement from form" do
    sign_in_as(users(:owner))

    assert_difference([ "Announcement.count", "ActivityLogEntry.count" ]) do
      post organization_announcements_path(organizations(:film_society)), params: {
        announcement: { title: "RSVP note", body: "For RSVPs.", audience: "event_rsvps", target_event_id: events(:upcoming_film_night).id, status: "published" }
      }
    end

    announcement = Announcement.order(:created_at).last
    assert_equal "event_rsvps", announcement.audience
    assert_equal events(:upcoming_film_night), announcement.target_event
    assert_equal "announcement.published", ActivityLogEntry.order(:created_at).last.action
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

    assert_difference("ActivityLogEntry.count") do
      patch organization_announcement_path(organizations(:film_society), announcement), params: {
        announcement: { title: announcement.title, body: announcement.body, audience: "officers", pinned: "0", status: "published" }
      }
    end

    assert_redirected_to organization_announcement_path(organizations(:film_society), announcement)
    assert_predicate announcement.reload, :published?
    assert_not_nil announcement.published_at
    assert_equal "announcement.published", ActivityLogEntry.order(:created_at).last.action
  end

  test "editing a published announcement preserves published at" do
    announcement = announcements(:pinned_all_members)
    published_at = announcement.published_at
    sign_in_as(users(:owner))

    assert_difference("ActivityLogEntry.count") do
      patch organization_announcement_path(organizations(:film_society), announcement), params: {
        announcement: { title: "Updated details", body: announcement.body, audience: "all_members", pinned: "1", status: "draft" }
      }
    end

    assert_predicate announcement.reload, :published?
    assert_equal published_at, announcement.published_at
    assert_equal "announcement.updated", ActivityLogEntry.order(:created_at).last.action
  end

  test "owner can remove an announcement and activity is logged" do
    sign_in_as(users(:owner))

    assert_difference("Announcement.count", -1) do
      assert_difference("ActivityLogEntry.count") do
        delete organization_announcement_path(organizations(:film_society), announcements(:officer_notes))
      end
    end

    assert_redirected_to organization_announcements_path(organizations(:film_society))
    assert_equal "announcement.removed", ActivityLogEntry.order(:created_at).last.action
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
      assert_difference("ActivityLogEntry.count") do
        post organization_announcements_path(organizations(:film_society)), params: {
          send_email: "1",
          announcement: { title: "Draft reminder", body: "Still being written.", audience: "all_members", status: "draft" }
        }
      end
    end

    assert_nil Announcement.order(:created_at).last.emailed_at
    assert_equal "announcement.drafted", ActivityLogEntry.order(:created_at).last.action
  end

  test "published announcement can be emailed when selected" do
    sign_in_as(users(:owner))

    assert_emails organizations(:film_society).memberships.count do
      assert_difference("ActivityLogEntry.count", 2) do
        post organization_announcements_path(organizations(:film_society)), params: {
          send_email: "1",
          announcement: { title: "Tonight's room", body: "Meet in the screening room.", audience: "all_members", status: "published" }
        }
      end
    end

    assert_not_nil Announcement.order(:created_at).last.emailed_at
    assert_equal "announcement.emailed", ActivityLogEntry.order(:created_at).last.action
  end

  test "disabling announcement emails prevents optional announcement email delivery" do
    memberships(:film_member).update!(announcement_emails_enabled: false)
    sign_in_as(users(:owner))

    assert_emails 1 do
      post organization_announcements_path(organizations(:film_society)), params: {
        send_email: "1",
        announcement: { title: "Room update", body: "Meet upstairs.", audience: "all_members", status: "published" }
      }
    end

    announcement = Announcement.order(:created_at).last
    assert_equal 1, announcement.announcement_deliveries.sent.count
    assert_equal 1, announcement.announcement_deliveries.skipped.count
  end

  test "organizer sees delivery summary on announcement detail" do
    announcement = announcements(:pinned_all_members)
    AnnouncementEmailSender.new(announcement: announcement).deliver
    sign_in_as(users(:owner))

    get organization_announcement_path(organizations(:film_society), announcement)

    assert_response :success
    assert_select "h2", "Email delivery"
    assert_select "p", text: /Sent to 2 members/
  end

  test "regular member cannot see delivery summary" do
    announcement = announcements(:pinned_all_members)
    AnnouncementEmailSender.new(announcement: announcement).deliver
    sign_in_as(users(:member))

    get organization_announcement_path(organizations(:film_society), announcement)

    assert_response :success
    assert_select "h2", { text: "Email delivery", count: 0 }
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end

  def create_targeted_announcement(audience:, target_event:)
    Announcement.create!(
      organization: organizations(:film_society),
      author: users(:owner),
      title: "#{audience.to_s.humanize} note",
      body: "A targeted announcement.",
      audience: audience,
      target_event: target_event,
      status: :published
    )
  end

  def create_user(name, email)
    User.create!(name: name, email_address: email, password: "password1234")
  end
end
