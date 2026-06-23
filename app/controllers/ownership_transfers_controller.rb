class OwnershipTransfersController < ApplicationController
  before_action :set_organization
  before_action :require_owner

  def update
    transfer = OwnershipTransfer.new(
      organization: @organization,
      target_membership_id: params[:membership_id]
    )

    if transfer.transfer
      redirect_to edit_organization_path(@organization), notice: "#{transfer.membership.user.name} is now an owner."
    else
      redirect_to edit_organization_path(@organization), alert: "Choose a current member to make an owner."
    end
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_owner
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
    head :forbidden unless OrganizationPolicy.new(current_user, @organization).transfer_ownership?
  end
end
