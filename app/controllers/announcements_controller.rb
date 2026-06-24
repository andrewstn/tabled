class AnnouncementsController < ApplicationController
  before_action :set_organization
  before_action :require_organization_membership
  before_action :require_active_organization, except: %i[index show]
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
    prepare_form
  end

  def create
    @announcement = @organization.announcements.new(announcement_params.merge(author: current_user, status: requested_status))

    if @announcement.save
      record_announcement_activity(@announcement.published? ? "announcement.published" : "announcement.drafted")
      deliver_announcement_email if email_requested?
      redirect_to organization_announcement_path(@organization, @announcement), notice: announcement_saved_notice
    else
      prepare_form
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    prepare_form
  end

  def update
    was_draft = @announcement.draft?
    status = @announcement.published? ? "published" : requested_status
    if @announcement.update(announcement_params.merge(status: status))
      record_announcement_activity(was_draft && @announcement.published? ? "announcement.published" : "announcement.updated")
      deliver_announcement_email if email_requested?
      redirect_to organization_announcement_path(@organization, @announcement), notice: announcement_saved_notice
    else
      prepare_form
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    title = @announcement.title
    @announcement.destroy!
    ActivityLog.record(
      organization: @organization,
      actor: current_user,
      action: "announcement.removed",
      subject: @announcement,
      summary: "#{current_user.name} removed #{title}.",
      metadata: { title: title }
    )
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
    params.expect(announcement: %i[title body audience target_event_id pinned])
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
    ActivityLog.record(
      organization: @organization,
      actor: current_user,
      action: "announcement.emailed",
      subject: @announcement,
      summary: "#{current_user.name} emailed #{@announcement.title}.",
      metadata: {
        title: @announcement.title,
        sent_count: @announcement.announcement_deliveries.sent.count,
        skipped_count: @announcement.announcement_deliveries.skipped.count
      }
    )
  end

  def prepare_form
    @target_events = @organization.events.order(starts_at: :desc)
    @delivery_preview = AnnouncementDeliveryPreview.new(@announcement)
  end

  def record_announcement_activity(action)
    verb = case action
    when "announcement.drafted"
      "drafted"
    when "announcement.published"
      "published"
    else
      "updated"
    end

    ActivityLog.record(
      organization: @organization,
      actor: current_user,
      action: action,
      subject: @announcement,
      summary: "#{current_user.name} #{verb} #{@announcement.title}.",
      metadata: { title: @announcement.title, audience: @announcement.audience }
    )
  end
end
