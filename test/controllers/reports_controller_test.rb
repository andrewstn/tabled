require "test_helper"
require "csv"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "owner can view semester report" do
    sign_in_as(users(:owner))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Semester report"
    assert_select "p", text: "A practical record of members, gatherings, and attendance."
    assert_select "dt", text: "Current members"
    assert_select "dd", text: organizations(:film_society).memberships.count.to_s
  end

  test "officer can view semester report" do
    memberships(:film_member).update!(role: :officer)
    sign_in_as(users(:member))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Semester report"
  end

  test "coordinator can view semester report" do
    memberships(:film_member).update!(role: :coordinator)
    sign_in_as(users(:member))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Semester report"
  end

  test "member cannot view organization report" do
    sign_in_as(users(:member))

    get organization_reports_path(organizations(:film_society))

    assert_response :forbidden
  end

  test "non-member cannot view report" do
    sign_in_as(users(:member))

    get organization_reports_path(organizations(:garden_club))

    assert_response :not_found
  end

  test "report summary is scoped to current organization" do
    10.times do |index|
      Event.create!(
        organization: organizations(:garden_club),
        created_by: users(:owner),
        title: "Garden planning #{index}",
        starts_at: 1.day.ago
      )
    end
    Membership.create!(organization: organizations(:garden_club), user: users(:owner), role: :officer)
    sign_in_as(users(:owner))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "dd", text: organizations(:film_society).memberships.count.to_s
    assert_select "dd", text: "10", count: 0
  end

  test "report shows member participation table" do
    sign_in_as(users(:owner))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "h2", "Participation record"
    assert_select "tbody th", text: /#{Regexp.escape(users(:owner).name)}/
    assert_select "span", text: users(:owner).email_address
    assert_select "td", text: "100%"
  end

  test "report paginates member participation rows" do
    11.times do |index|
      user = create_user(name: "Report Member #{format("%02d", index)}", email: "report-member-#{index}@example.test")
      Membership.create!(organization: organizations(:film_society), user: user, role: :member)
    end
    sign_in_as(users(:owner))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "section[aria-labelledby='member-participation'] tbody tr", count: 10
    assert_select "nav[aria-label='Pagination']", text: /Showing 1–10 of 13/
    assert_select "a[href$='#member-participation']", text: "Next"

    get organization_reports_path(organizations(:film_society)), params: { page: 2 }

    assert_response :success
    assert_select "section[aria-labelledby='member-participation'] tbody tr", count: 3
    assert_select "nav[aria-label='Pagination']", text: /Showing 11–13 of 13/
    assert_select "a[href$='#member-participation']", text: "Previous"
    assert_select "section[aria-labelledby='member-participation'] tbody", text: /Report Member/
  end

  test "report shows held gathering summaries without upcoming events" do
    sign_in_as(users(:owner))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "h2", "Held gatherings"
    assert_select "a[href=?]", organization_event_path(organizations(:film_society), events(:past_planning_table)), text: events(:past_planning_table).title
    assert_select "a[href=?]", organization_event_path(organizations(:film_society), events(:upcoming_film_night)), count: 0
  end

  test "roster CSV export is organization scoped" do
    outsider = create_user(name: "Garden Member", email: "garden-member@example.test")
    Membership.create!(organization: organizations(:garden_club), user: outsider, role: :member)
    sign_in_as(users(:owner))

    assert_difference("ActivityLogEntry.count") do
      get roster_organization_reports_path(organizations(:film_society), format: :csv)
    end

    assert_response :success
    rows = CSV.parse(response.body, headers: true)
    assert_equal [ "Name", "Email", "Role", "Joined at" ], rows.headers
    assert_includes rows["Email"], users(:owner).email_address
    assert_not_includes rows["Email"], outsider.email_address
    assert_equal "report.exported", ActivityLogEntry.order(:created_at).last.action
    assert_equal "roster", ActivityLogEntry.order(:created_at).last.metadata["report"]
  end

  test "participation CSV export is organization scoped" do
    outsider = create_user(name: "Garden Member", email: "garden-participation@example.test")
    Membership.create!(organization: organizations(:garden_club), user: outsider, role: :member)
    sign_in_as(users(:owner))

    assert_difference("ActivityLogEntry.count") do
      get participation_organization_reports_path(organizations(:film_society), format: :csv)
    end

    assert_response :success
    rows = CSV.parse(response.body, headers: true)
    assert_equal "RSVP attending count", rows.headers.fetch(4)
    assert_includes rows["Email"], users(:owner).email_address
    assert_not_includes rows["Email"], outsider.email_address
    assert_equal "participation", ActivityLogEntry.order(:created_at).last.metadata["report"]
  end

  test "event summary CSV export is organization scoped" do
    Event.create!(
      organization: organizations(:garden_club),
      created_by: users(:owner),
      title: "Garden records night",
      starts_at: 1.day.ago
    )
    Membership.create!(organization: organizations(:garden_club), user: users(:owner), role: :officer)
    sign_in_as(users(:owner))

    assert_difference("ActivityLogEntry.count") do
      get events_organization_reports_path(organizations(:film_society), format: :csv)
    end

    assert_response :success
    rows = CSV.parse(response.body, headers: true)
    assert_equal [ "Event title", "Starts at", "Location", "RSVP attending count", "Present count", "Late count", "Excused count", "Absent count", "Attendance recorded" ], rows.headers
    assert_includes rows["Event title"], events(:past_planning_table).title
    assert_not_includes rows["Event title"], events(:upcoming_film_night).title
    assert_not_includes rows["Event title"], "Garden records night"
    assert_equal "event summary", ActivityLogEntry.order(:created_at).last.metadata["report"]
  end

  test "member cannot export reports" do
    sign_in_as(users(:member))

    get roster_organization_reports_path(organizations(:film_society), format: :csv)

    assert_response :forbidden
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end

  def create_user(name:, email:)
    User.create!(
      name: name,
      email_address: email,
      password: "password1234",
      password_confirmation: "password1234"
    )
  end
end
