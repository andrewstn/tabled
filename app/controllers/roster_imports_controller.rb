class RosterImportsController < ApplicationController
  before_action :set_organization
  before_action :require_active_organization
  before_action :require_import_manager

  def new
  end

  def create
    if roster_import_params[:csv_file].blank?
      flash.now[:alert] = "Choose a CSV file to import."
      return render :new, status: :unprocessable_entity
    end

    @result = RosterImporter.new(
      organization: @organization,
      invited_by: current_user,
      csv_content: roster_import_params[:csv_file].read
    ).import
    flash.now[:notice] = "#{helpers.pluralize(@result.created_count, "invitation")} created." if @result.created_count.positive?
    render :new, status: :ok
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_import_manager
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
    head :forbidden unless InvitationPolicy.new(current_user, @organization).manage?
  end

  def roster_import_params
    params.fetch(:roster_import, {}).permit(:csv_file)
  end
end
