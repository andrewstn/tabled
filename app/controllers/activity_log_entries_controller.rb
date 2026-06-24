class ActivityLogEntriesController < ApplicationController
  before_action :set_organization
  before_action :require_log_book_viewer

  def show
    @action_filter = params[:action_filter].to_s
    @action_options = @organization.activity_log_entries.distinct.order(:action).pluck(:action)

    entries = @organization.activity_log_entries.includes(:actor).recent_first
    entries = entries.where(action: @action_filter) if @action_options.include?(@action_filter)

    @paginator = Paginator.new(entries, page: params[:page])
    @activity_log_entries = @paginator.records
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_log_book_viewer
    policy = OrganizationPolicy.new(current_user, @organization)
    raise ActiveRecord::RecordNotFound unless policy.show?
    head :forbidden unless policy.view_activity?
  end
end
