require "test_helper"

class AttendanceRecordTest < ActiveSupport::TestCase
  test "supports attendance statuses" do
    record = attendance_records(:owner_present_planning_table)

    assert_predicate record, :present?
    assert record.update(status: :late)
    assert record.update(status: :excused)
    assert record.update(status: :absent)
  end

  test "allows one record per membership and event" do
    duplicate = AttendanceRecord.new(
      event: events(:past_planning_table),
      membership: memberships(:film_owner),
      status: :present
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:membership_id], "has already been taken"
  end

  test "membership must belong to the event organization" do
    garden_event = Event.create!(
      organization: organizations(:garden_club),
      created_by: users(:owner),
      title: "Garden work day",
      starts_at: 1.day.ago
    )
    record = AttendanceRecord.new(
      event: garden_event,
      membership: memberships(:film_member),
      status: :present
    )

    assert_not record.valid?
    assert_includes record.errors[:membership], "must belong to the event organization"
  end
end
