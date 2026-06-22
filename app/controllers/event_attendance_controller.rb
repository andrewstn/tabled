class EventAttendanceController < ApplicationController
  before_action :set_organization
  before_action :require_organization_membership
  before_action :set_event
  before_action :require_attendance_manager

  def show
    @memberships = @organization.memberships.includes(:user).order("users.name")
    @rsvps_by_membership_id = @event.rsvps.index_by(&:membership_id)
    @attendance_by_membership_id = @event.attendance_records.includes(:marked_by).index_by(&:membership_id)
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
      redirect_to organization_event_attendance_path(@organization, @event), notice: "Saved to the event record."
    else
      redirect_to organization_event_attendance_path(@organization, @event), alert: marker.attendance_record.errors.full_messages.to_sentence
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
end
