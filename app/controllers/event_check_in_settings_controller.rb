class EventCheckInSettingsController < ApplicationController
  before_action :set_organization_and_event
  before_action :require_check_in_manager
  before_action :require_active_organization

  def update
    case params[:operation]
    when "open"
      code = @event.regenerate_check_in_code
      @event.update!(check_in_opens_at: Time.current, check_in_closes_at: duration_minutes.minutes.from_now)
      ActivityLog.record(
        organization: @organization,
        actor: current_user,
        action: "check_in.opened",
        subject: @event,
        summary: "#{current_user.name} opened check-in for #{@event.title}.",
        metadata: { event_title: @event.title, duration_minutes: duration_minutes }
      )
      redirect_with_code(code, "Check-in is open.")
    when "close"
      @event.update!(check_in_closes_at: Time.current)
      ActivityLog.record(
        organization: @organization,
        actor: current_user,
        action: "check_in.closed",
        subject: @event,
        summary: "#{current_user.name} closed check-in for #{@event.title}.",
        metadata: { event_title: @event.title }
      )
      redirect_to organization_event_path(@organization, @event), notice: "Check-in has closed for this gathering."
    when "regenerate"
      code = @event.regenerate_check_in_code
      @event.save!
      ActivityLog.record(
        organization: @organization,
        actor: current_user,
        action: "check_in.regenerated",
        subject: @event,
        summary: "#{current_user.name} regenerated the check-in code for #{@event.title}.",
        metadata: { event_title: @event.title }
      )
      redirect_with_code(code, "A new check-in code is ready.")
    else
      head :unprocessable_entity
    end
  end

  private

  def set_organization_and_event
    @organization = Organization.find_by!(slug: params[:organization_slug])
    @event = @organization.events.find(params[:event_id])
  end

  def require_check_in_manager
    head :forbidden unless EventPolicy.new(current_user, @organization, @event).manage_attendance?
  end

  def duration_minutes
    params.fetch(:duration_minutes, 60).to_i.clamp(5, 240)
  end

  def redirect_with_code(code, notice)
    flash[:check_in_code] = code
    redirect_to organization_event_path(@organization, @event), notice: notice
  end
end
