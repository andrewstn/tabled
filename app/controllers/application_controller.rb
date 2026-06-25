class ApplicationController < ActionController::Base
  before_action :require_authentication
  before_action :prevent_public_demo_mutation

  helper_method :authenticated?, :current_user, :public_demo_mode?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def current_user
    Current.user ||= User.find_by(id: session[:user_id])
  end

  def authenticated?
    current_user.present?
  end

  def require_authentication
    return if authenticated?

    session[:return_to_after_authenticating] = request.fullpath if request.get? || request.head?
    redirect_to new_session_path, alert: "Sign in to open your organizations."
  end

  def start_new_session_for(user)
    reset_session
    session[:user_id] = user.id
  end

  def require_active_organization
    return unless @organization&.archived?

    redirect_to organization_path(@organization), alert: "Restore this organization before making changes."
  end

  def public_demo_mode?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("TABLED_PUBLIC_DEMO", "false"))
  end

  def prevent_public_demo_mutation
    return unless public_demo_mode?
    return unless authenticated?
    return unless current_user.demo_account?
    return if request.get? || request.head?
    return if controller_path == "sessions"

    redirect_back fallback_location: root_path, alert: "Public demo mode keeps this workspace read-only so it stays intact for everyone."
  end

  def terminate_session
    reset_session
    Current.reset
  end
end
