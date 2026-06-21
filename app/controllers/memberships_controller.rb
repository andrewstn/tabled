class MembershipsController < ApplicationController
  before_action :set_organization
  before_action :require_organization_membership
  before_action :set_membership, only: %i[update destroy]

  def index
    @current_membership = current_user.memberships.find_by!(organization: @organization)
    @memberships = @organization.memberships.includes(:user).order(:role, "users.name")
    @can_manage_members = OrganizationPolicy.new(current_user, @organization).manage?
  end

  def update
    new_role = membership_params[:role]
    policy = MembershipPolicy.new(current_user, @organization, @membership)
    return head :forbidden unless policy.update_role?(new_role)

    if MembershipRoleUpdater.new(membership: @membership, role: new_role).update
      redirect_to organization_members_path(@organization), notice: "#{@membership.user.name} is now #{@membership.role.humanize.downcase}."
    else
      redirect_to organization_members_path(@organization), alert: @membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    policy = MembershipPolicy.new(current_user, @organization, @membership)
    return head :forbidden unless policy.remove?

    member_name = @membership.user.name
    destination = @membership.user == current_user ? root_path : organization_members_path(@organization)

    if MembershipRemover.new(membership: @membership).remove
      redirect_to destination, notice: "#{member_name} was removed from #{@organization.name}."
    else
      redirect_to organization_members_path(@organization), alert: @membership.errors.full_messages.to_sentence
    end
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_organization_membership
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
  end

  def set_membership
    @membership = @organization.memberships.find(params[:id])
  end

  def membership_params
    params.expect(membership: [ :role ])
  end
end
