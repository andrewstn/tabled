class InvitationMailer < ApplicationMailer
  def invite
    @invitation = params[:invitation]
    @acceptance_url = invitation_acceptance_url(params[:token])

    mail(
      to: @invitation.email,
      subject: "You’ve been invited to join #{@invitation.organization.name} on Tabled"
    )
  end
end
