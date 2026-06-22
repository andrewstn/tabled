require "test_helper"
require "csv"

class EventAttendanceControllerTest < ActionDispatch::IntegrationTest
  test "owner can view attendance sheet" do
    sign_in_as(users(:owner))

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table))

    assert_response :success
    assert_select "h1", "Attendance sheet"
    assert_select "p", text: /RSVPs show who planned to come/
    assert_select "h3", users(:member).name
    assert_select ".role-tag", text: "Late"
    assert_select "legend", text: "Mark attendance"
    assert_select "turbo-frame#attendance-member-#{memberships(:film_member).id}", count: 1
  end

  test "officer can view attendance sheet" do
    memberships(:film_member).update!(role: :officer)
    sign_in_as(users(:member))

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table))

    assert_response :success
  end

  test "member cannot view attendance sheet" do
    sign_in_as(users(:member))

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table))

    assert_response :forbidden
  end

  test "non-member cannot view attendance sheet" do
    sign_in_as(users(:member))

    get organization_event_attendance_path(organizations(:garden_club), events(:past_planning_table))

    assert_response :not_found
  end

  test "organizer can mark and update a member attendance" do
    sign_in_as(users(:owner))
    event = events(:upcoming_film_night)

    assert_difference("AttendanceRecord.count") do
      patch organization_event_attendance_record_path(organizations(:film_society), event, memberships(:film_member)), params: {
        attendance_record: { status: "present", note: "At the camera table" }
      }
    end

    record = event.attendance_records.find_by!(membership: memberships(:film_member))
    assert_predicate record, :present?
    assert_equal users(:owner), record.marked_by
    assert_not_nil record.checked_in_at
    assert_redirected_to organization_event_attendance_path(
      organizations(:film_society),
      event,
      anchor: "attendance-member-#{memberships(:film_member).id}"
    )

    assert_no_difference("AttendanceRecord.count") do
      patch organization_event_attendance_record_path(organizations(:film_society), event, memberships(:film_member)), params: {
        attendance_record: { status: "absent", note: "" }
      }
    end

    assert_predicate record.reload, :absent?
    assert_nil record.checked_in_at
  end

  test "attendance sheet paginates organization members" do
    26.times { |index| create_member(name: "Attendance Member #{index}", email: "attendance-#{index}@example.test") }
    sign_in_as(users(:owner))

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table))

    assert_select "turbo-frame[id^='attendance-member-']", count: 25
    assert_select "nav[aria-label='Pagination']", text: /Showing 1–25 of 28/
  end

  test "attendance sheet searches by name and email within the organization" do
    target = create_member(name: "Unique Attendance Name", email: "special-attendance@example.test")
    outsider = create_member(name: "Hidden Attendance Name", email: "hidden-attendance@example.test", organization: organizations(:garden_club))
    sign_in_as(users(:owner))

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table)), params: { q: "unique attendance" }
    assert_select "h3", target.user.name

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table)), params: { q: "SPECIAL-ATTENDANCE@EXAMPLE" }
    assert_select "h3", target.user.name
    assert_select "h3", text: outsider.user.name, count: 0
  end

  test "attendance sheet filters RSVP responses and no responses" do
    no_response = create_member(name: "No RSVP Student", email: "no-rsvp@example.test")
    sign_in_as(users(:owner))

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table)), params: { rsvp: "maybe" }
    assert_select "h3", users(:member).name
    assert_select "h3", text: users(:owner).name, count: 0

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table)), params: { rsvp: "no_response" }
    assert_select "h3", no_response.user.name
    assert_select "h3", text: users(:member).name, count: 0
  end

  test "attendance sheet filters attendance statuses and unmarked members" do
    unmarked = create_member(name: "Unmarked Student", email: "unmarked@example.test")
    sign_in_as(users(:owner))

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table)), params: { attendance: "late" }
    assert_select "h3", users(:member).name
    assert_select "h3", text: users(:owner).name, count: 0

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table)), params: { attendance: "unmarked" }
    assert_select "h3", unmarked.user.name
    assert_select "h3", text: users(:member).name, count: 0
  end

  test "attendance pagination and marking preserve filters" do
    26.times { |index| create_member(name: "Filtered Attendee #{index}", email: "filtered-attendee-#{index}@example.test") }
    sign_in_as(users(:owner))

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table)), params: { q: "Filtered", rsvp: "no_response", attendance: "unmarked" }
    assert_select "a", text: "Next" do |links|
      query = Rack::Utils.parse_nested_query(URI.parse(links.first["href"]).query)
      assert_equal({ "q" => "Filtered", "rsvp" => "no_response", "attendance" => "unmarked", "page" => "2" }, query)
    end

    target = organizations(:film_society).memberships.joins(:user).find_by!(users: { email_address: "filtered-attendee-0@example.test" })
    patch organization_event_attendance_record_path(organizations(:film_society), events(:past_planning_table), target), params: {
      q: "Filtered", rsvp: "no_response", attendance: "unmarked", page: "2",
      attendance_record: { status: "present", note: "Made it" }
    }
    assert_redirected_to organization_event_attendance_path(
      organizations(:film_society), events(:past_planning_table),
      q: "Filtered", rsvp: "no_response", attendance: "unmarked", page: "2",
      anchor: "attendance-member-#{target.id}"
    )
  end

  test "member cannot mark attendance" do
    sign_in_as(users(:member))

    assert_no_difference("AttendanceRecord.count") do
      patch organization_event_attendance_record_path(organizations(:film_society), events(:upcoming_film_night), memberships(:film_member)), params: {
        attendance_record: { status: "present" }
      }
    end

    assert_response :forbidden
  end

  test "organizer cannot mark a membership from another organization" do
    garden_membership = Membership.create!(user: users(:member), organization: organizations(:garden_club), role: :member)
    sign_in_as(users(:owner))

    assert_no_difference("AttendanceRecord.count") do
      patch organization_event_attendance_record_path(organizations(:film_society), events(:upcoming_film_night), garden_membership), params: {
        attendance_record: { status: "present" }
      }
    end

    assert_response :not_found
  end

  test "organizer can export attendance CSV" do
    sign_in_as(users(:owner))

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table), format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    rows = CSV.parse(response.body, headers: true)
    member_row = rows.find { |row| row["Email"] == users(:member).email_address }
    assert_equal users(:member).name, member_row["Member name"]
    assert_equal "maybe", member_row["RSVP status"]
    assert_equal "late", member_row["Attendance status"]
    assert_predicate member_row["Checked in at"], :present?
    assert_equal users(:owner).name, member_row["Marked by"]
  end

  test "member cannot export attendance CSV" do
    sign_in_as(users(:member))

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table), format: :csv)

    assert_response :forbidden
  end

  private

  def create_member(name:, email:, organization: organizations(:film_society))
    user = User.create!(name: name, email_address: email, password: "password1234")
    Membership.create!(organization: organization, user: user, role: :member)
  end

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
