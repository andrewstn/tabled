class EventPolicy
  def initialize(user, organization, event = nil)
    @membership = user.memberships.find_by(organization: organization)
    @event = event
  end

  def index?
    @membership.present?
  end

  def show?
    @membership.present? && event_in_organization?
  end

  def create?
    organizer?
  end

  def update?
    organizer? && event_in_organization?
  end

  def destroy?
    (@membership&.owner? || @membership&.officer?) && event_in_organization?
  end

  def view_roster?
    organizer? && event_in_organization?
  end

  def override_rsvp_limits?
    organizer? && event_in_organization?
  end

  def manage_attendance?
    organizer? && event_in_organization?
  end

  private

  def organizer?
    @membership&.owner? || @membership&.officer? || @membership&.coordinator?
  end

  def event_in_organization?
    @event.nil? || @event.organization_id == @membership&.organization_id
  end
end
