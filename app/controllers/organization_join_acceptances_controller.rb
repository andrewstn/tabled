class OrganizationJoinAcceptancesController < ApplicationController
  skip_before_action :require_authentication
  before_action :set_join_link

  def show
    session[:return_to_after_authenticating] = organization_join_path(params[:token]) if @join_link&.available? && !authenticated?
    @existing_membership = current_user&.memberships&.find_by(organization: @join_link.organization) if @join_link
  end

  private

  def set_join_link
    @join_link = OrganizationJoinLink.find_by_token(params[:token])
    render :show, status: :not_found unless @join_link
  end
end
