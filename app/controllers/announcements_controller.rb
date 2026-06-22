class AnnouncementsController < ApplicationController
  before_action :set_organization
  before_action :require_organization_membership

  def index
    @membership = current_user.memberships.find_by!(organization: @organization)
    @announcement_policy = AnnouncementPolicy.new(current_user, @organization)
    @published_announcements = @organization.announcements
      .published_for(@membership)
      .includes(:author)
      .bulletin_order
    @draft_announcements = @organization.announcements.draft.includes(:author).order(updated_at: :desc) if @announcement_policy.manage?
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_organization_membership
    raise ActiveRecord::RecordNotFound unless AnnouncementPolicy.new(current_user, @organization).index?
  end
end
