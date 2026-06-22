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

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
