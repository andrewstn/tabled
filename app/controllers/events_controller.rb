class EventsController < ApplicationController
  before_action :set_organization
  before_action :require_organization_membership

  def index
    @membership = current_user.memberships.find_by!(organization: @organization)
    @upcoming_events = @organization.events.upcoming.includes(:rsvps)
    @past_events = @organization.events.past.includes(:rsvps)
    @rsvps_by_event_id = @membership.rsvps.where(event: @organization.events).index_by(&:event_id)
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_organization_membership
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
  end
end
