require "test_helper"

class SemesterReportTest < ActiveSupport::TestCase
  test "member participation counts rsvps and attendance statuses" do
    report = SemesterReport.new(organization: organizations(:film_society))

    owner_row = report.member_participation.find { |row| row.membership == memberships(:film_owner) }
    member_row = report.member_participation.find { |row| row.membership == memberships(:film_member) }

    assert_equal 1, owner_row.rsvp_attending_count
    assert_equal 1, owner_row.present_count
    assert_equal 0, owner_row.late_count
    assert_equal 0, owner_row.excused_count
    assert_equal 0, owner_row.absent_count
    assert_equal 100, owner_row.attendance_rate

    assert_equal 0, member_row.rsvp_attending_count
    assert_equal 0, member_row.present_count
    assert_equal 1, member_row.late_count
    assert_equal 0, member_row.excused_count
    assert_equal 0, member_row.absent_count
    assert_equal 100, member_row.attendance_rate
  end

  test "attendance rate excludes past events without attendance records" do
    Event.create!(
      organization: organizations(:film_society),
      created_by: users(:owner),
      title: "Unrecorded gathering",
      starts_at: 1.day.ago
    )

    report = SemesterReport.new(organization: organizations(:film_society))
    owner_row = report.member_participation.find { |row| row.membership == memberships(:film_owner) }

    assert_equal 1, report.events_with_attendance_recorded
    assert_equal 100, owner_row.attendance_rate
  end

  test "attendance rate is unavailable without recorded attendance" do
    AttendanceRecord.where(event: organizations(:film_society).events).destroy_all

    report = SemesterReport.new(organization: organizations(:film_society))
    owner_row = report.member_participation.find { |row| row.membership == memberships(:film_owner) }

    assert_nil owner_row.attendance_rate
    assert_equal "Not enough attendance recorded", owner_row.attendance_rate_label
  end

  test "last attended uses the most recent present or late record" do
    newer_event = Event.create!(
      organization: organizations(:film_society),
      created_by: users(:owner),
      title: "Recent recorded gathering",
      starts_at: 1.hour.ago
    )
    newer_event.attendance_records.create!(
      membership: memberships(:film_owner),
      marked_by: users(:owner),
      status: :late,
      checked_in_at: 45.minutes.ago
    )

    report = SemesterReport.new(organization: organizations(:film_society))
    owner_row = report.member_participation.find { |row| row.membership == memberships(:film_owner) }

    assert_equal newer_event, owner_row.last_attended_record.event
  end

  test "event summaries count rsvps and attendance statuses" do
    report = SemesterReport.new(organization: organizations(:film_society))
    summary = report.event_summaries.find { |row| row.event == events(:past_planning_table) }

    assert_equal 0, summary.rsvp_attending_count
    assert_equal 1, summary.present_count
    assert_equal 1, summary.late_count
    assert_equal 0, summary.excused_count
    assert_equal 0, summary.absent_count
    assert_predicate summary, :attendance_recorded?
  end

  test "event summaries exclude future events" do
    report = SemesterReport.new(organization: organizations(:film_society))

    assert_includes report.event_summaries.map(&:event), events(:past_planning_table)
    assert_not_includes report.event_summaries.map(&:event), events(:upcoming_film_night)
  end

  test "event summary shows capacity usage when capacity exists" do
    event = Event.create!(
      organization: organizations(:film_society),
      created_by: users(:owner),
      title: "Past screening with capacity",
      starts_at: 2.days.ago,
      capacity: 12
    )
    event.rsvps.create!(membership: memberships(:film_owner), status: :attending)
    event.attendance_records.create!(membership: memberships(:film_owner), marked_by: users(:owner), status: :present)

    report = SemesterReport.new(organization: organizations(:film_society))
    summary = report.event_summaries.find { |row| row.event == event }

    assert_equal "1 of 12", summary.capacity_usage
  end
end
