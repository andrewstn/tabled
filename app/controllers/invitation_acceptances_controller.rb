class InvitationAcceptancesController < ApplicationController
  skip_before_action :require_authentication
  before_action :set_invitation

  def show
    @invited_user = User.find_by(email_address: @invitation.email)
    session[:return_to_after_authenticating] = invitation_acceptance_path(params[:token]) if @invitation.pending? && !authenticated?
  end

  def update
    unless authenticated?
      session[:return_to_after_authenticating] = invitation_acceptance_path(params[:token])
      return redirect_to new_session_path, alert: "Sign in to accept this invitation."
    end

    return head :forbidden unless @invitation.email.casecmp?(current_user.email_address)

    accepter = InvitationAccepter.new(invitation: @invitation, user: current_user)
    if accepter.accept
      redirect_to organization_path(@invitation.organization), notice: "You joined #{@invitation.organization.name}."
    else
      redirect_to invitation_acceptance_path(params[:token]), alert: @invitation.errors.full_messages.to_sentence
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_by_token(params[:token])
    raise ActiveRecord::RecordNotFound unless @invitation
  end
end
