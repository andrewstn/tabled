class OrganizationArchivesController < ApplicationController
  before_action :set_organization
  before_action :require_owner

  def update
    @organization.archive!
    redirect_to organization_path(@organization), notice: "#{@organization.name} is archived."
  end

  def destroy
    @organization.restore!
    redirect_to organization_path(@organization), notice: "#{@organization.name} is restored."
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_owner
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
    head :forbidden unless OrganizationPolicy.new(current_user, @organization).archive?
  end
end
