class MembershipsController < ApplicationController
  before_action :set_organization
  before_action :require_organization_membership
  before_action :set_membership, only: %i[show update destroy]

  def index
    @current_membership = current_user.memberships.find_by!(organization: @organization)
    memberships = @organization.memberships.joins(:user).includes(:user).order("users.name", "memberships.id")
    @search_query = params[:q].to_s.strip
    @role_filter = params[:role].to_s
    if @search_query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@search_query)}%"
      memberships = memberships.where("users.name ILIKE :pattern OR users.email_address ILIKE :pattern", pattern: pattern)
    end
    memberships = memberships.where(role: @role_filter) if Membership::ROLES.include?(@role_filter)
    @paginator = Paginator.new(memberships, page: params[:page])
    @memberships = @paginator.records
    @can_view_reports = ReportPolicy.new(current_user, @organization).show?
    @can_manage_members = OrganizationPolicy.new(current_user, @organization).manage?
    if @can_manage_members
      @pending_invitation_count = @organization.invitations.pending.count
      @active_join_link_count = @organization.organization_join_links.available.count
    end
  end

  def show
    return head :forbidden unless MembershipPolicy.new(current_user, @organization, @membership).view_attendance_history?

    @attendance_records = @membership.attendance_records
      .joins(:event)
      .where(events: { organization_id: @organization.id })
      .includes(:event, :marked_by)
      .order("events.starts_at DESC")
    @rsvps_by_event_id = @membership.rsvps.where(event_id: @attendance_records.map(&:event_id)).index_by(&:event_id)
  end

  def update
    new_role = membership_params[:role]
    policy = MembershipPolicy.new(current_user, @organization, @membership)
    return head :forbidden unless policy.update_role?(new_role)

    if MembershipRoleUpdater.new(membership: @membership, role: new_role).update
      redirect_to organization_members_path(@organization), notice: "Member role updated."
    else
      redirect_to organization_members_path(@organization), alert: @membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    policy = MembershipPolicy.new(current_user, @organization, @membership)
    return head :forbidden unless policy.remove?

    member_name = @membership.user.name
    destination = @membership.user == current_user ? root_path : organization_members_path(@organization)

    if MembershipRemover.new(membership: @membership).remove
      redirect_to destination, notice: "#{member_name} was removed from the roster."
    else
      redirect_to organization_members_path(@organization), alert: @membership.errors.full_messages.to_sentence
    end
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_organization_membership
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
  end

  def set_membership
    @membership = @organization.memberships.find(params[:id])
  end

  def membership_params
    params.expect(membership: [ :role ])
  end
end
