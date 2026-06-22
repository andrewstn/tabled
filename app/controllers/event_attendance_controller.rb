require "csv"

class EventAttendanceController < ApplicationController
  before_action :set_organization
  before_action :require_organization_membership
  before_action :set_event
  before_action :require_attendance_manager

  def show
    @memberships = @organization.memberships.includes(:user).order("users.name")
    @rsvps_by_membership_id = @event.rsvps.index_by(&:membership_id)
    @attendance_by_membership_id = @event.attendance_records.includes(:marked_by).index_by(&:membership_id)

    respond_to do |format|
      format.html
      format.csv do
        send_data attendance_csv,
          filename: "event-#{@event.id}-attendance.csv",
          type: "text/csv; charset=utf-8"
      end
    end
  end

  def update
    membership = @organization.memberships.find(params[:membership_id])
    marker = AttendanceMarker.new(
      event: @event,
      membership: membership,
      status: attendance_params[:status],
      note: attendance_params[:note],
      marked_by: current_user
    )

    if marker.save
      redirect_to attendance_sheet_path(membership), notice: "Saved to the event record."
    else
      redirect_to attendance_sheet_path(membership), alert: marker.attendance_record.errors.full_messages.to_sentence
    end
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_organization_membership
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
  end

  def set_event
    @event = @organization.events.find(params[:event_id])
  end

  def require_attendance_manager
    head :forbidden unless EventPolicy.new(current_user, @organization, @event).manage_attendance?
  end

  def attendance_params
    params.expect(attendance_record: %i[status note])
  end

  def attendance_csv
    CSV.generate(headers: true) do |csv|
      csv << [ "Member name", "Email", "Role", "RSVP status", "Attendance status", "Checked in at", "Marked by", "Note" ]
      @memberships.each do |membership|
        rsvp = @rsvps_by_membership_id[membership.id]
        attendance = @attendance_by_membership_id[membership.id]
        csv << [
          safe_csv_cell(membership.user.name),
          safe_csv_cell(membership.user.email_address),
          membership.role,
          rsvp&.status,
          attendance&.status,
          attendance&.checked_in_at&.iso8601,
          safe_csv_cell(attendance&.marked_by&.name),
          safe_csv_cell(attendance&.note)
        ]
      end
    end
  end

  def safe_csv_cell(value)
    value.to_s.match?(/\A[=+\-@]/) ? "'#{value}" : value
  end

  def attendance_sheet_path(membership)
    organization_event_attendance_path(
      @organization,
      @event,
      anchor: "attendance-member-#{membership.id}"
    )
  end
end
