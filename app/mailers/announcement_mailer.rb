class AnnouncementMailer < ApplicationMailer
  def announcement
    @announcement = params[:announcement]
    @recipient = params[:recipient]
    @announcement_url = organization_announcement_url(@announcement.organization, @announcement)

    mail(
      to: @recipient.email_address,
      subject: "[#{@announcement.organization.name}] New announcement: #{@announcement.title}"
    )
  end
end
