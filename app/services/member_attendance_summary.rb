class MemberAttendanceSummary
  def initialize(attendance_records)
    @attendance_records = attendance_records
  end

  def present_count
    status_count("present")
  end

  def late_count
    status_count("late")
  end

  def excused_count
    status_count("excused")
  end

  def absent_count
    status_count("absent")
  end

  def attended_count
    present_count
  end

  def recorded_event_count
    present_count + late_count + excused_count + absent_count
  end

  def attendance_rate
    return nil if recorded_event_count.zero?

    (((present_count + late_count).to_f / recorded_event_count) * 100).round
  end

  def attendance_rate_label
    return "Not enough attendance recorded" unless attendance_rate

    "#{attendance_rate}%"
  end

  private

  attr_reader :attendance_records

  def status_count(status)
    counts.fetch(status, 0)
  end

  def counts
    @counts ||= attendance_records.group_by(&:status).transform_values(&:size)
  end
end
