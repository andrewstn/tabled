class EventCheckInSettingsController < ApplicationController
  before_action :set_organization_and_event
  before_action :require_check_in_manager

  def update
    case params[:operation]
    when "open"
      code = @event.regenerate_check_in_code
      @event.update!(check_in_opens_at: Time.current, check_in_closes_at: duration_minutes.minutes.from_now)
      redirect_with_code(code, "Member check-in is open.")
    when "close"
      @event.update!(check_in_closes_at: Time.current)
      redirect_to organization_event_path(@organization, @event), notice: "Member check-in is closed."
    when "regenerate"
      code = @event.regenerate_check_in_code
      @event.save!
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
