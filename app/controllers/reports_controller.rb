class ReportsController < ApplicationController
  before_action :set_organization
  before_action :require_report_viewer

  def show
    @report = SemesterReport.new(organization: @organization)
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_report_viewer
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
    head :forbidden unless ReportPolicy.new(current_user, @organization).show?
  end
end
