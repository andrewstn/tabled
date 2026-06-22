class AnnouncementEmailSender
  def initialize(announcement:)
    @announcement = announcement
  end

  def deliver
    return false unless @announcement.published?

    @announcement.recipient_memberships.find_each do |membership|
      AnnouncementMailer.with(announcement: @announcement, recipient: membership.user).announcement.deliver_now
    end
    @announcement.update!(emailed_at: Time.current)
  end
end
