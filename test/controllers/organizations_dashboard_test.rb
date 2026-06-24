require "test_helper"

class OrganizationsDashboardTest < ActionDispatch::IntegrationTest
  test "organizations page keeps the create organization link" do
    sign_in_as(users(:owner))

    get root_path

    assert_response :success
    assert_select "h1", "Your organizations"
    assert_select "a[href=?]", new_organization_path, text: "+ Add another organization"
  end

  test "a member sees the organization dashboard and their role" do
    organizations(:film_society).update!(
      contact_email: "film@example.test",
      website_url: "https://film.example.test",
      meeting_note: "Student Union screening room",
      current_semester_label: "Fall 2026"
    )
    sign_in_as(users(:member))

    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", organizations(:film_society).name
    assert_select "dt", text: "Current semester"
    assert_select "dd", text: "Fall 2026"
    assert_select "a[href='mailto:film@example.test']", text: "film@example.test"
    assert_select "a[href='https://film.example.test']", text: "https://film.example.test"
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
    assert_select "h3", text: announcements(:pinned_all_members).title
    assert_select "p", text: "Pinned"
    assert_select "p", text: "Nothing needs follow-up right now."
    assert_select "p", text: "Recent changes are available to organization organizers.", count: 0
    assert_select "p", text: "Log book", count: 0
    assert_select "h2", text: "Recent activity", count: 0
    assert_select "a[href=?]", organization_log_book_path(organizations(:film_society)), count: 0
    assert_select "h3", text: events(:past_planning_table).title
    assert_select "p", text: /2 members present or late/
    assert_select "a[href=?]", organization_members_path(organizations(:film_society)), text: /Member roster/
    assert_select "a[href=?]", organization_communication_preferences_path(organizations(:film_society)), text: "Communication preferences"
    assert_select "a[href=?]", organization_events_path(organizations(:film_society)), text: "Gatherings"
    assert_select "a[href=?]", organization_announcements_path(organizations(:film_society)), text: "Bulletin"
    assert_select "a[href=?]", organization_reports_path(organizations(:film_society)), count: 0
    assert_select "a[href=?]", organization_log_book_path(organizations(:film_society)), count: 0
    assert_select "a[href=?]", account_settings_path, text: "Account settings"
    assert_select "a[href=?]", edit_organization_path(organizations(:film_society)), text: "Organization settings", count: 0
    assert_select "a[href=?]", new_organization_invitation_path(organizations(:film_society)), count: 0
    assert_select "a[href=?]", new_organization_announcement_path(organizations(:film_society)), count: 0
    assert_select "summary", text: "Membership options"
    assert_select "a[href=?]", organization_communication_preferences_path(organizations(:film_society)), text: "Communication preferences →"
  end

  test "owner sees member onboarding actions backed by pending invitations" do
    sign_in_as(users(:owner))

    get organization_path(organizations(:film_society))

    assert_select "nav[aria-label='Organization sections']" do
      assert_select "a[href=?]", organization_announcements_path(organizations(:film_society)), text: "Bulletin"
      assert_select "a[href=?]", organization_events_path(organizations(:film_society)), text: "Gatherings"
      assert_select "a[href=?]", organization_members_path(organizations(:film_society)), text: "Member roster"
      assert_select "a[href=?]", organization_reports_path(organizations(:film_society)), text: "Semester report"
      assert_select "a[href=?]", organization_log_book_path(organizations(:film_society)), text: "Log book"
      assert_select "a[href=?]", organization_communication_preferences_path(organizations(:film_society)), count: 0
      assert_select "a[href=?]", new_organization_invitation_path(organizations(:film_society)), count: 0
      assert_select "a[href=?]", organization_invitations_path(organizations(:film_society)), count: 0
      assert_select "a[href=?]", edit_organization_path(organizations(:film_society)), count: 0
    end
    assert_select "a[href=?]", edit_organization_path(organizations(:film_society)), text: "Open organization settings →"
    assert_select "a[href=?]", organization_communication_preferences_path(organizations(:film_society)), text: "Communication preferences →"
    assert_select "a[href=?]", organization_reports_path(organizations(:film_society)), text: "Semester report"
    assert_select "h2", text: "Semester report"
    assert_select "p", text: /members · \d+ gathering recorded/
    assert_select "a[href=?]", new_organization_event_path(organizations(:film_society)), count: 0
    assert_select "a[href=?]", new_organization_announcement_path(organizations(:film_society)), count: 0
    assert_select "span", text: "1 draft", count: 0
    assert_select "p", text: "No notes in the log book yet."
  end

  test "dashboard member preview paginates around the table" do
    11.times do |index|
      user = User.create!(
        name: "Dashboard Member #{format("%02d", index)}",
        email_address: "dashboard-member-#{index}@example.test",
        password: "password1234"
      )
      Membership.create!(organization: organizations(:film_society), user: user, role: :member)
    end
    sign_in_as(users(:owner))

    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select ".member-row", count: 10
    assert_select "nav[aria-label='Pagination']", text: /Showing 1–10 of 13/
    assert_select "a", text: "Next"

    get organization_path(organizations(:film_society)), params: { page: 2 }

    assert_response :success
    assert_select ".member-row", count: 3
    assert_select "nav[aria-label='Pagination']", text: /Showing 11–13 of 13/
    assert_select ".member-row", text: /Dashboard Member/
  end

  test "dashboard shows recent activity from the current organization to organizers" do
    ActivityLogEntry.create!(
      organization: organizations(:film_society),
      actor: users(:owner),
      action: "event.created",
      summary: "Alex created Camera Workshop.",
      occurred_at: 1.minute.ago
    )
    ActivityLogEntry.create!(
      organization: organizations(:garden_club),
      actor: users(:owner),
      action: "event.created",
      summary: "Alex created Garden Work Day.",
      occurred_at: Time.current
    )
    sign_in_as(users(:owner))

    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select "h2", "Recent activity"
    assert_select "p", text: "Alex created Camera Workshop."
    assert_select "p", text: "Alex created Garden Work Day.", count: 0
    assert_select "a[href=?]", organization_log_book_path(organizations(:film_society)), text: "Open log book →"
  end

  test "dashboard does not show recent activity to ordinary members" do
    ActivityLogEntry.create!(
      organization: organizations(:film_society),
      actor: users(:owner),
      action: "settings.updated",
      summary: "Alex updated organization settings."
    )
    sign_in_as(users(:member))

    get organization_path(organizations(:film_society))

    assert_select "p", text: "Alex updated organization settings.", count: 0
    assert_select "a[href=?]", organization_log_book_path(organizations(:film_society)), count: 0
    assert_select "p", text: "Log book", count: 0
    assert_select "h2", text: "Recent activity", count: 0
    assert_select "p", text: "Recent changes are available to organization organizers.", count: 0
  end

  test "coordinator sees semester report entry point" do
    memberships(:film_member).update!(role: :coordinator)
    sign_in_as(users(:member))

    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select "nav[aria-label='Organization sections']" do
      assert_select "a[href=?]", organization_reports_path(organizations(:film_society)), text: "Semester report"
      assert_select "a[href=?]", organization_log_book_path(organizations(:film_society)), text: "Log book"
      assert_select "a[href=?]", organization_communication_preferences_path(organizations(:film_society)), count: 0
    end
  end

  test "officer sees report and log book navigation" do
    memberships(:film_member).update!(role: :officer)
    sign_in_as(users(:member))

    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select "nav[aria-label='Organization sections']" do
      assert_select "a[href=?]", organization_reports_path(organizations(:film_society)), text: "Semester report"
      assert_select "a[href=?]", organization_log_book_path(organizations(:film_society)), text: "Log book"
      assert_select "a[href=?]", organization_communication_preferences_path(organizations(:film_society)), count: 0
    end
  end

  test "dashboard shows bulletin empty state from real data" do
    organizations(:film_society).announcements.destroy_all
    sign_in_as(users(:member))

    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select "p", text: "The board is clear."
  end

  test "dashboard shows real attendance follow ups for organizers" do
    missing_event = Event.create!(
      organization: organizations(:film_society),
      created_by: users(:owner),
      title: "Unmarked workshop",
      starts_at: 2.days.ago
    )
    open_event = events(:upcoming_film_night)
    open_event.regenerate_check_in_code
    open_event.update!(check_in_opens_at: 1.minute.ago, check_in_closes_at: 1.hour.from_now)
    sign_in_as(users(:owner))

    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select "li", text: /Check-in is open for #{Regexp.escape(open_event.title)}/
    assert_select "a[href=?]", organization_event_attendance_path(organizations(:film_society), missing_event), text: missing_event.title
  end

  test "ordinary member does not see organizer attendance follow ups" do
    Event.create!(organization: organizations(:film_society), created_by: users(:owner), title: "Unmarked workshop", starts_at: 2.days.ago)
    sign_in_as(users(:member))

    get organization_path(organizations(:film_society))

    assert_select "p", text: "Nothing needs follow-up right now."
    assert_select "a", text: "Unmarked workshop", count: 0
    assert_select "a[href=?]", organization_reports_path(organizations(:film_society)), count: 0
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
      assert_select "a[href=?]", root_path, text: "Your organizations"
      assert_select "a[href=?]", organization_path(organizations(:film_society))
      assert_select "a[href=?]", organization_path(organizations(:garden_club))
      assert_select "a[aria-current='page'][href=?]", organization_path(organizations(:film_society))
      assert_select "a[href=?]", new_organization_path, count: 0
      assert_select "a[href=?]", edit_organization_path(organizations(:film_society)), count: 0
    end
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
