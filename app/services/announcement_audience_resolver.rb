class AnnouncementAudienceResolver
  def initialize(announcement)
    @announcement = announcement
    @organization = announcement.organization
  end

  def memberships
    scope = @organization.memberships.includes(:user)

    case @announcement.audience
    when "all_members"
      scope
    when "officers"
      scope.where(role: %w[owner officer coordinator])
    when "event_rsvps"
      return scope.none unless @announcement.target_event

      scope.where(id: @announcement.target_event.rsvps.select(:membership_id))
    when "event_attendees"
      return scope.none unless @announcement.target_event

      scope.where(id: @announcement.target_event.attendance_records.where(status: %w[present late]).select(:membership_id))
    else
      scope.none
    end
  end

  def visible_to?(membership)
    return false unless membership&.organization_id == @organization.id

    memberships.exists?(membership.id)
  end
end
