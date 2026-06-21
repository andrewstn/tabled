class OrganizationsController < ApplicationController
  def new
    @organization = Organization.new
  end

  def create
    creator = OrganizationCreator.new(owner: current_user, attributes: organization_params)

    if creator.create
      redirect_to organization_path(creator.organization), notice: "The table is set. Welcome to #{creator.organization.name}."
    else
      @organization = creator.organization
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @organization = current_user.organizations.find_by!(slug: params[:slug])
    @membership = current_user.memberships.find_by!(organization: @organization)
  end

  private

  def organization_params
    params.expect(organization: %i[name description])
  end
end
