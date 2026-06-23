class CommunicationPreferencesController < ApplicationController
  before_action :set_organization
  before_action :set_membership

  def show
  end

  def update
    if @membership.update(preference_params)
      redirect_to organization_communication_preferences_path(@organization), notice: "Communication preferences updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def set_membership
    @membership = current_user.memberships.find_by!(organization: @organization)
  end

  def preference_params
    params.expect(membership: %i[
      announcement_emails_enabled
      event_reminder_emails_enabled
      recruitment_emails_enabled
    ])
  end
end
