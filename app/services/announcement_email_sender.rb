class AnnouncementEmailSender
  def initialize(announcement:)
    @announcement = announcement
  end

  def deliver
    return false unless @announcement.published?

    @announcement.recipient_memberships.distinct.find_each do |membership|
      next if @announcement.announcement_deliveries.sent.exists?(membership: membership)

      if membership.user.email_address.blank?
        record_delivery(membership, :skipped, skipped_reason: "missing_email")
      elsif !membership.announcement_emails_enabled?
        record_delivery(membership, :skipped, skipped_reason: "announcement_emails_disabled")
      else
        AnnouncementMailer.with(announcement: @announcement, recipient: membership.user).announcement.deliver_now
        record_delivery(membership, :sent, sent_at: Time.current)
      end
    end
    @announcement.update!(emailed_at: Time.current)
  end

  private

  def record_delivery(membership, status, sent_at: nil, skipped_reason: nil)
    delivery = @announcement.announcement_deliveries.find_or_initialize_by(membership: membership)
    delivery.assign_attributes(
      user: membership.user,
      email: membership.user.email_address,
      status: status,
      sent_at: sent_at,
      skipped_reason: skipped_reason
    )
    delivery.save!
  end
end
