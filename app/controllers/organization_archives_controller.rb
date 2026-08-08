class OrganizationArchivesController < ApplicationController
  before_action :set_organization
  before_action :require_owner

  def update
    @organization.archive!
    ActivityLog.record(
      organization: @organization,
      actor: current_user,
      action: "organization.archived",
      subject: @organization,
      summary: "#{current_user.name} archived #{@organization.name}.",
      metadata: { organization_name: @organization.name }
    )
    redirect_to organization_path(@organization), notice: "#{@organization.name} is archived."
  end

  def destroy
    @organization.restore!
    ActivityLog.record(
      organization: @organization,
      actor: current_user,
      action: "organization.restored",
      subject: @organization,
      summary: "#{current_user.name} restored #{@organization.name}.",
      metadata: { organization_name: @organization.name }
    )
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
