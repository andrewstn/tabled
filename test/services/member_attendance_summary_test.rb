require "test_helper"

class MemberAttendanceSummaryTest < ActiveSupport::TestCase
  test "calculates attendance rate from the member attendance records" do
    summary = MemberAttendanceSummary.new([
      AttendanceRecord.new(status: :present),
      AttendanceRecord.new(status: :late),
      AttendanceRecord.new(status: :absent)
    ])

    assert_equal 67, summary.attendance_rate
    assert_equal "67%", summary.attendance_rate_label
    assert_equal 1, summary.present_count
    assert_equal 1, summary.late_count
    assert_equal 1, summary.absent_count
  end

  test "reports not enough attendance when no records exist" do
    summary = MemberAttendanceSummary.new([])

    assert_nil summary.attendance_rate
    assert_equal "Not enough attendance recorded", summary.attendance_rate_label
    assert_equal 0, summary.recorded_event_count
  end
end
