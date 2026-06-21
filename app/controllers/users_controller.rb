class UsersController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create]

  def new
    redirect_to root_path if authenticated?
    @invitation = invitation_from_params
    @user = User.new(email_address: @invitation&.email)
  end

  def create
    @user = User.new(user_params)
    @invitation = invitation_from_params

    if @user.save
      start_new_session_for(@user)
      finish_signup
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: %i[name email_address password password_confirmation])
  end

  def invitation_from_params
    Invitation.find_by_token(params[:invitation_token])
  end

  def finish_signup
    return redirect_to root_path, notice: "Your member account is ready." unless @invitation

    accepter = InvitationAccepter.new(invitation: @invitation, user: @user)
    if accepter.accept
      redirect_to organization_path(@invitation.organization), notice: "Your account is ready, and you joined #{@invitation.organization.name}."
    else
      redirect_to invitation_acceptance_path(params[:invitation_token]), alert: @invitation.errors.full_messages.to_sentence
    end
  end
end
