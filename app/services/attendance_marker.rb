class AttendanceMarker
  attr_reader :attendance_record

  def initialize(event:, membership:, status:, marked_by: nil, note: nil)
    @event = event
    @membership = membership
    @status = status
    @marked_by = marked_by
    @note = note
  end

  def save
    @event.with_lock do
      @attendance_record = @event.attendance_records.find_or_initialize_by(membership: @membership)
      @attendance_record.assign_attributes(status: @status, marked_by: @marked_by, note: @note)

      if %w[present late].include?(@status.to_s)
        @attendance_record.checked_in_at ||= Time.current
      else
        @attendance_record.checked_in_at = nil
      end

      @attendance_record.save
    end
  end
end
