require "test_helper"

class EventCheckInsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:upcoming_film_night)
    @code = @event.regenerate_check_in_code
    @event.update!(check_in_opens_at: 5.minutes.ago, check_in_closes_at: 1.hour.from_now)
  end

  test "member can self check in with valid code during open window" do
    sign_in_as(users(:member))

    assert_difference("AttendanceRecord.count") do
      post organization_event_check_in_path(organizations(:film_society), @event), params: { check_in_code: @code }
    end

    record = @event.attendance_records.find_by!(membership: memberships(:film_member))
    assert_predicate record, :present?
    assert_equal users(:member), record.marked_by
    assert_not_nil record.checked_in_at
    assert_equal "You’re checked in.", flash[:notice]
  end

  test "self check in updates an existing attendance record to present" do
    existing = @event.attendance_records.create!(membership: memberships(:film_member), status: :excused, note: "Previously excused")
    sign_in_as(users(:member))

    assert_no_difference("AttendanceRecord.count") do
      post organization_event_check_in_path(organizations(:film_society), @event), params: { check_in_code: @code.downcase }
    end

    assert_predicate existing.reload, :present?
    assert_equal "Previously excused", existing.note
    assert_not_nil existing.checked_in_at
  end

  test "member cannot check in with invalid code" do
    sign_in_as(users(:member))

    assert_no_difference("AttendanceRecord.count") do
      post organization_event_check_in_path(organizations(:film_society), @event), params: { check_in_code: "WRONG1" }
    end

    assert_equal "That code does not match this gathering.", flash[:alert]
  end

  test "member cannot check in before window opens" do
    @event.update!(check_in_opens_at: 1.hour.from_now, check_in_closes_at: 2.hours.from_now)
    sign_in_as(users(:member))

    post organization_event_check_in_path(organizations(:film_society), @event), params: { check_in_code: @code }

    assert_equal "Check-in not started. Your organizer will share a code when the gathering begins.", flash[:alert]
  end

  test "member cannot check in after window closes" do
    @event.update!(check_in_opens_at: 2.hours.ago, check_in_closes_at: 1.hour.ago)
    sign_in_as(users(:member))

    post organization_event_check_in_path(organizations(:film_society), @event), params: { check_in_code: @code }

    assert_equal "Check-in has closed for this gathering.", flash[:alert]
  end

  test "member already checked in gets a specific confirmation" do
    record = @event.attendance_records.create!(membership: memberships(:film_member), status: :present, checked_in_at: 2.minutes.ago)
    original_check_in = record.checked_in_at
    sign_in_as(users(:member))

    assert_no_changes -> { record.reload.updated_at } do
      post organization_event_check_in_path(organizations(:film_society), @event), params: { check_in_code: @code }
    end

    assert_equal original_check_in, record.reload.checked_in_at
    assert_equal "You’re already checked in.", flash[:notice]
  end

  test "member cannot check in to another organization event" do
    garden_event = Event.create!(organization: organizations(:garden_club), created_by: users(:owner), title: "Garden meeting", starts_at: 1.hour.from_now)
    garden_event.regenerate_check_in_code
    garden_event.update!(check_in_opens_at: 1.minute.ago, check_in_closes_at: 1.hour.from_now)
    sign_in_as(users(:member))

    assert_no_difference("AttendanceRecord.count") do
      post organization_event_check_in_path(organizations(:garden_club), garden_event), params: { check_in_code: @code }
    end

    assert_response :not_found
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
