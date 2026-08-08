class AnnouncementDeliveryPreview
  def initialize(announcement)
    @announcement = announcement
  end

  def visible_count
    audience_memberships.count
  end

  def email_recipient_count
    audience_memberships.where(announcement_emails_enabled: true).count
  end

  def skipped_for_preferences_count
    audience_memberships.where(announcement_emails_enabled: false).count
  end

  private

  def audience_memberships
    @audience_memberships ||= AnnouncementAudienceResolver.new(@announcement).memberships
  end
end
