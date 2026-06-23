class RsvpsController < ApplicationController
  before_action :set_organization_and_event
  before_action :require_organization_membership
  before_action :require_active_organization

  def create
    save_rsvp
  end

  def update
    save_rsvp
  end

  private

  def set_organization_and_event
    @organization = Organization.find_by!(slug: params[:organization_slug])
    @event = @organization.events.find(params[:event_id])
  end

  def require_organization_membership
    @membership = current_user.memberships.find_by(organization: @organization)
    raise ActiveRecord::RecordNotFound unless @membership
  end

  def save_rsvp
    updater = RsvpUpdater.new(
      event: @event,
      membership: @membership,
      attributes: rsvp_params,
      override_limits: EventPolicy.new(current_user, @organization, @event).override_rsvp_limits?
    )

    if updater.save
      redirect_to organization_event_path(@organization, @event), notice: "RSVP saved."
    else
      redirect_to organization_event_path(@organization, @event), alert: updater.rsvp.errors.full_messages.to_sentence
    end
  end

  def rsvp_params
    params.expect(rsvp: %i[status note])
  end
end
