class OrganizationsController < ApplicationController
  before_action :set_organization, only: %i[show edit update]
  before_action :require_organization_membership, only: :show
  before_action :require_organization_manager, only: %i[edit update]

  def new
    @organization = Organization.new
  end

  def create
    creator = OrganizationCreator.new(owner: current_user, attributes: organization_params)

    if creator.create
      redirect_to organization_path(creator.organization), notice: "#{creator.organization.name} is ready."
    else
      @organization = creator.organization
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @membership = current_user.memberships.find_by!(organization: @organization)
    @can_manage_members = organization_policy.manage?
    @can_view_reports = ReportPolicy.new(current_user, @organization).show?
    @pending_invitation_count = @organization.invitations.pending.count if @can_manage_members
    dashboard_members = @organization.memberships.joins(:user).includes(:user).order("users.name", "memberships.id")
    @member_paginator = Paginator.new(dashboard_members, page: params[:page], per_page: 10)
    @dashboard_memberships = @member_paginator.records
    @upcoming_events = @organization.events.upcoming.includes(:rsvps).limit(3)
    @dashboard_rsvps = @membership.rsvps.where(event: @upcoming_events).index_by(&:event_id)
    @can_create_events = EventPolicy.new(current_user, @organization).create?
    @can_view_activity = organization_policy.view_activity?
    @announcement_policy = AnnouncementPolicy.new(current_user, @organization)
    @bulletin_announcement = @organization.announcements.published_for(@membership).bulletin_order.first
    @recent_attendance_events = @organization.events.past
      .joins(:attendance_records)
      .distinct
      .includes(:attendance_records)
      .limit(3)
    load_report_preview if @can_view_reports
    load_attendance_follow_ups if @can_create_events
    load_recent_activity if @can_view_activity
  end

  def edit
    @owner_transfer_memberships = @organization.memberships.includes(:user).where.not(user: current_user).order("users.name")
  end

  def update
    if @organization.update(organization_params)
      ActivityLog.record(
        organization: @organization,
        actor: current_user,
        action: "settings.updated",
        subject: @organization,
        summary: "#{current_user.name} updated organization settings.",
        metadata: { changed_fields: organization_params.keys }
      )
      redirect_to organization_path(@organization), notice: "Organization details updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:slug])
  end

  def require_organization_membership
    raise ActiveRecord::RecordNotFound unless organization_policy.show?
  end

  def require_organization_manager
    head :forbidden unless organization_policy.manage?
  end

  def organization_policy
    @organization_policy ||= OrganizationPolicy.new(current_user, @organization)
  end

  def organization_params
    params.expect(organization: %i[name description contact_email website_url meeting_note current_semester_label])
  end

  def load_attendance_follow_ups
    @attendance_follow_ups = []

    @organization.events
      .where(check_in_opens_at: ..Time.current)
      .where("check_in_closes_at IS NULL OR check_in_closes_at > ?", Time.current)
      .order(:starts_at)
      .limit(3)
      .each { |event| @attendance_follow_ups << [ :check_in_open, event ] }

    @organization.events.past
      .where(starts_at: 30.days.ago..Time.current)
      .left_outer_joins(:attendance_records)
      .where(attendance_records: { id: nil })
      .limit(3)
      .each { |event| @attendance_follow_ups << [ :attendance_missing, event ] }
  end

  def load_report_preview
    @semester_report = SemesterReport.new(organization: @organization)
    @events_needing_attendance_count = @organization.events.past
      .left_outer_joins(:attendance_records)
      .where(attendance_records: { id: nil })
      .count
  end

  def load_recent_activity
    @recent_activity_entries = @organization.activity_log_entries.includes(:actor).recent_first.limit(3)
  end
end
