require "test_helper"

class AttendanceMarkerTest < ActiveSupport::TestCase
  test "present creates a record and sets checked in time" do
    event = events(:upcoming_film_night)

    assert_difference("AttendanceRecord.count") do
      assert AttendanceMarker.new(event: event, membership: memberships(:film_member), status: :present, marked_by: users(:owner)).save
    end

    record = event.attendance_records.find_by!(membership: memberships(:film_member))
    assert_predicate record, :present?
    assert_not_nil record.checked_in_at
    assert_equal users(:owner), record.marked_by
  end

  test "late preserves an existing check in time" do
    record = attendance_records(:owner_present_planning_table)
    checked_in_at = record.checked_in_at

    assert AttendanceMarker.new(event: record.event, membership: record.membership, status: :late, marked_by: users(:owner)).save

    assert_equal checked_in_at, record.reload.checked_in_at
  end

  test "absent and excused clear checked in time" do
    record = attendance_records(:owner_present_planning_table)

    assert AttendanceMarker.new(event: record.event, membership: record.membership, status: :absent, marked_by: users(:owner)).save
    assert_nil record.reload.checked_in_at

    record.update!(status: :present, checked_in_at: Time.current)
    assert AttendanceMarker.new(event: record.event, membership: record.membership, status: :excused, marked_by: users(:owner)).save
    assert_nil record.reload.checked_in_at
  end
end
