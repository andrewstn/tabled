class OrganizationLeavesController < ApplicationController
  before_action :set_organization
  before_action :set_membership

  def destroy
    if MembershipRemover.new(membership: @membership).remove
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
