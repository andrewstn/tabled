class InvitationsController < ApplicationController
  before_action :set_organization
  before_action :require_invitation_manager
  before_action :set_invitation, only: :destroy

  def index
    @invitations = @organization.invitations.includes(:invited_by).order(created_at: :desc)
  end

  def new
    @invitation = @organization.invitations.new
    set_permitted_roles
  end

  def create
    role = invitation_params[:role]
    return head :forbidden unless invitation_policy.invite_as?(role)

    issuer = InvitationIssuer.new(
      organization: @organization,
      invited_by: current_user,
      attributes: invitation_params
    )

    if issuer.create
      InvitationMailer.with(invitation: issuer.invitation, token: issuer.invitation.token).invite.deliver_now
      redirect_to organization_invitations_path(@organization), notice: "Invitation sent to #{issuer.invitation.email}."
    else
      @invitation = issuer.invitation
      set_permitted_roles
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    return head :forbidden unless invitation_policy.revoke?(@invitation)

    if @invitation.pending?
      @invitation.update!(revoked_at: Time.current)
      redirect_to organization_invitations_path(@organization), notice: "Invitation for #{@invitation.email} was revoked."
    else
      redirect_to organization_invitations_path(@organization), alert: "That invitation is no longer pending."
    end
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_invitation_manager
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
    head :forbidden unless invitation_policy.manage?
  end

  def set_invitation
    @invitation = @organization.invitations.find(params[:id])
  end

  def invitation_policy
    @invitation_policy ||= InvitationPolicy.new(current_user, @organization)
  end

  def invitation_params
    params.expect(invitation: %i[email role])
  end

  def set_permitted_roles
    @permitted_roles = invitation_policy.permitted_roles
  end
end
