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
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
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
    params.expect(organization: %i[name description])
  end
end
