class EventsController < ApplicationController
  before_action :set_organization
  before_action :require_organization_membership
  before_action :set_event, only: :show

  def index
    @membership = current_user.memberships.find_by!(organization: @organization)
    @upcoming_events = @organization.events.upcoming.includes(:rsvps)
    @past_events = @organization.events.past.includes(:rsvps)
    @rsvps_by_event_id = @membership.rsvps.where(event: @organization.events).index_by(&:event_id)
  end

  def show
    @membership = current_user.memberships.find_by!(organization: @organization)
    @rsvp = @event.rsvps.find_by(membership: @membership)
    @event_policy = EventPolicy.new(current_user, @organization, @event)
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_organization_membership
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
  end

  def set_event
    @event = @organization.events.includes(rsvps: { membership: :user }).find(params[:id])
    raise ActiveRecord::RecordNotFound unless EventPolicy.new(current_user, @organization, @event).show?
  end
end
