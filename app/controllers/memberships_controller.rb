class MembershipsController < ApplicationController
  before_action :set_organization
  before_action :require_organization_membership

  def index
    @current_membership = current_user.memberships.find_by!(organization: @organization)
    @memberships = @organization.memberships.includes(:user).order(:role, "users.name")
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_organization_membership
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
  end
end
