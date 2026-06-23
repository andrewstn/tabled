class EventCheckInsController < ApplicationController
  before_action :set_organization_and_event
  before_action :set_membership
  before_action :require_active_organization

  def create
    unless @event.check_in_open?
      return redirect_to organization_event_path(@organization, @event), alert: check_in_window_message
    end

    unless @event.valid_check_in_code?(params[:check_in_code])
      return redirect_to organization_event_path(@organization, @event), alert: "That code does not match this gathering."
    end

    existing_record = @event.attendance_records.find_by(membership: @membership)
    if existing_record&.present?
      return redirect_to organization_event_path(@organization, @event), notice: "You’re already checked in."
    end

    marker = AttendanceMarker.new(
      event: @event,
      membership: @membership,
      status: :present,
      marked_by: current_user,
      note: existing_record&.note
    )

    if marker.save
      redirect_to organization_event_path(@organization, @event), notice: "You’re checked in."
    else
      redirect_to organization_event_path(@organization, @event), alert: marker.attendance_record.errors.full_messages.to_sentence
    end
  end

  private

  def set_organization_and_event
    @organization = Organization.find_by!(slug: params[:organization_slug])
    @event = @organization.events.find(params[:event_id])
  end

  def set_membership
    @membership = current_user.memberships.find_by(organization: @organization)
    raise ActiveRecord::RecordNotFound unless @membership
  end

  def check_in_window_message
    if @event.check_in_opens_at.blank? || @event.check_in_opens_at > Time.current
      "Check-in not started. Your organizer will share a code when the gathering begins."
    else
      "Check-in has closed for this gathering."
    end
  end
end
