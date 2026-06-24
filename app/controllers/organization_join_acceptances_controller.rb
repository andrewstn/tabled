class OrganizationJoinAcceptancesController < ApplicationController
  skip_before_action :require_authentication, only: :show
  before_action :set_join_link

  def show
    session[:return_to_after_authenticating] = organization_join_path(params[:token]) if @join_link&.available? && !authenticated?
    @existing_membership = current_user&.memberships&.find_by(organization: @join_link.organization) if @join_link
  end

  def update
    accepter = OrganizationJoinLinkAccepter.new(join_link: @join_link, user: current_user)

    if accepter.accept
      ActivityLog.record(
        organization: @join_link.organization,
        actor: current_user,
        action: "member.joined_recruitment_link",
        subject: accepter.membership,
        summary: "#{current_user.name} joined through #{@join_link.label}.",
        metadata: { link_label: @join_link.label, role: accepter.membership.role }
      )
      redirect_to organization_path(@join_link.organization), notice: "You joined #{@join_link.organization.name}."
    elsif accepter.already_joined?
      redirect_to organization_path(@join_link.organization), notice: "You’re already a member of #{@join_link.organization.name}."
    else
      @existing_membership = current_user.memberships.find_by(organization: @join_link.organization)
      flash.now[:alert] = @join_link.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_join_link
    @join_link = OrganizationJoinLink.find_by_token(params[:token])
    render :show, status: :not_found unless @join_link
  end
end
