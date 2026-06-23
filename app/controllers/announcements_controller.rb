class AnnouncementsController < ApplicationController
  before_action :set_organization
  before_action :require_organization_membership
  before_action :set_announcement, only: %i[show edit update destroy]
  before_action :require_announcement_creator, only: %i[new create]
  before_action :require_announcement_manager, only: %i[edit update destroy]

  def index
    @membership = current_user.memberships.find_by!(organization: @organization)
    @announcement_policy = AnnouncementPolicy.new(current_user, @organization)
    @published_announcements = @organization.announcements
      .published_for(@membership)
      .includes(:author)
      .bulletin_order
    @draft_announcements = @organization.announcements.draft.includes(:author).order(updated_at: :desc) if @announcement_policy.manage?
  end

  def show
    @announcement_policy = AnnouncementPolicy.new(current_user, @organization, @announcement)
    raise ActiveRecord::RecordNotFound unless @announcement_policy.show?
  end

  def new
    @announcement = @organization.announcements.new(author: current_user, audience: :all_members)
  end

  def create
    @announcement = @organization.announcements.new(announcement_params.merge(author: current_user, status: requested_status))

    if @announcement.save
      deliver_announcement_email if email_requested?
      redirect_to organization_announcement_path(@organization, @announcement), notice: announcement_saved_notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    status = @announcement.published? ? "published" : requested_status
    if @announcement.update(announcement_params.merge(status: status))
      deliver_announcement_email if email_requested?
      redirect_to organization_announcement_path(@organization, @announcement), notice: announcement_saved_notice
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @announcement.destroy!
    redirect_to organization_announcements_path(@organization), notice: "Announcement removed."
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_organization_membership
    raise ActiveRecord::RecordNotFound unless AnnouncementPolicy.new(current_user, @organization).index?
  end

  def set_announcement
    @announcement = @organization.announcements.includes(:author).find(params[:id])
  end

  def require_announcement_creator
    head :forbidden unless AnnouncementPolicy.new(current_user, @organization).create?
  end

  def require_announcement_manager
    head :forbidden unless AnnouncementPolicy.new(current_user, @organization, @announcement).update?
  end

  def announcement_params
    params.expect(announcement: %i[title body audience pinned])
  end

  def requested_status
    params.dig(:announcement, :status) == "published" ? "published" : "draft"
  end

  def announcement_saved_notice
    @announcement.published? ? "Announcement published." : "Draft saved."
  end

  def email_requested?
    params[:send_email] == "1" && @announcement.published? && @announcement.emailed_at.nil?
  end

  def deliver_announcement_email
    AnnouncementEmailSender.new(announcement: @announcement).deliver
  end
end
