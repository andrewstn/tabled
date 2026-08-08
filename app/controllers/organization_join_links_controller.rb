class OrganizationJoinLinksController < ApplicationController
  before_action :set_organization
  before_action :require_active_organization, except: :index
  before_action :require_join_link_manager
  before_action :set_join_link, only: :destroy

  def index
    @join_links = @organization.organization_join_links.includes(:created_by).order(created_at: :desc)
  end

  def new
    @join_link = @organization.organization_join_links.new(role: :member)
  end

  def create
    @join_link = @organization.organization_join_links.new(join_link_params.merge(created_by: current_user, role: :member))

    if @join_link.save
      ActivityLog.record(
        organization: @organization,
        actor: current_user,
        action: "recruitment_link.created",
        subject: @join_link,
        summary: "#{current_user.name} created the #{@join_link.label} recruitment link.",
        metadata: { label: @join_link.label, role: @join_link.role, max_uses: @join_link.max_uses }
      )
      redirect_to organization_join_links_path(@organization), notice: "Recruitment link created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @join_link.update!(active: false)
    ActivityLog.record(
      organization: @organization,
      actor: current_user,
      action: "recruitment_link.disabled",
      subject: @join_link,
      summary: "#{current_user.name} disabled the #{@join_link.label} recruitment link.",
      metadata: { label: @join_link.label }
    )
    redirect_to organization_join_links_path(@organization), notice: "Recruitment link disabled."
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_join_link_manager
    policy = OrganizationPolicy.new(current_user, @organization)
    raise ActiveRecord::RecordNotFound unless policy.show?
    head :forbidden unless policy.manage?
  end

  def set_join_link
    @join_link = @organization.organization_join_links.find(params[:id])
  end

  def join_link_params
    params.expect(organization_join_link: %i[label expires_at max_uses])
  end
end
