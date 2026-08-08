class OrganizationLeavesController < ApplicationController
  before_action :set_organization
  before_action :set_membership

  def destroy
    member_name = @membership.user.name
    if MembershipRemover.new(membership: @membership).remove
      ActivityLog.record(
        organization: @organization,
        actor: current_user,
        action: "member.left",
        subject: @membership,
        summary: "#{member_name} left #{@organization.name}.",
        metadata: { member_name: member_name, role: @membership.role }
      )
      redirect_to root_path, notice: "You left #{@organization.name}."
    else
      redirect_to organization_path(@organization), alert: @membership.errors.full_messages.to_sentence
    end
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def set_membership
    @membership = current_user.memberships.find_by!(organization: @organization)
  end
end
