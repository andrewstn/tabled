class AnnouncementPolicy
  def initialize(user, organization, announcement = nil)
    @membership = user.memberships.find_by(organization: organization)
    @announcement = announcement
  end

  def index?
    @membership.present?
  end

  def show?
    return false unless @membership && announcement_in_organization?
    return manager? if @announcement.draft?
    return true if manager?

    @announcement.published? && audience_visible?
  end

  def create?
    manager?
  end

  def update?
    manager? && announcement_in_organization?
  end

  def destroy?
    update?
  end

  def publish?
    update?
  end

  def manage?
    manager?
  end

  private

  def manager?
    @membership&.owner? || @membership&.officer?
  end

  def organizer?
    manager? || @membership&.coordinator?
  end

  def audience_visible?
    AnnouncementAudienceResolver.new(@announcement).visible_to?(@membership)
  end

  def announcement_in_organization?
    @announcement.nil? || @announcement.organization_id == @membership&.organization_id
  end
end
