class EventsController < ApplicationController
  before_action :set_organization
  before_action :require_organization_membership
  before_action :set_event, only: %i[show edit update destroy]
  before_action :require_event_creator, only: %i[new create]
  before_action :require_event_editor, only: %i[edit update]
  before_action :require_event_destroyer, only: :destroy

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
    @rsvps_by_status = @event.rsvps.group_by(&:status) if @event_policy.view_roster?
  end

  def new
    @event = @organization.events.new(created_by: current_user)
  end

  def create
    @event = @organization.events.new(event_params.merge(created_by: current_user))

    if @event.save
      redirect_to organization_event_path(@organization, @event), notice: "#{@event.title} was added to the calendar."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to organization_event_path(@organization, @event), notice: "Gathering details updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    title = @event.title
    @event.destroy!
    redirect_to organization_events_path(@organization), notice: "#{title} was removed from the calendar."
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

  def require_event_creator
    head :forbidden unless EventPolicy.new(current_user, @organization).create?
  end

  def require_event_editor
    head :forbidden unless EventPolicy.new(current_user, @organization, @event).update?
  end

  def require_event_destroyer
    head :forbidden unless EventPolicy.new(current_user, @organization, @event).destroy?
  end

  def event_params
    params.expect(event: %i[title description location starts_at ends_at capacity rsvp_deadline])
  end
end
