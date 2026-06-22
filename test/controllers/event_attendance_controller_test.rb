require "test_helper"

class EventAttendanceControllerTest < ActionDispatch::IntegrationTest
  test "owner can view attendance sheet" do
    sign_in_as(users(:owner))

    get organization_event_attendance_path(organizations(:film_society), events(:past_planning_table))

    assert_response :success
    assert_select "h1", "Attendance sheet"
    assert_select "h3", users(:member).name
    assert_select ".role-tag", text: "Late"
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

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
