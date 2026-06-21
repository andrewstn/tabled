class ApplicationController < ActionController::Base
  before_action :require_authentication

  helper_method :authenticated?, :current_user

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

  def terminate_session
    reset_session
    Current.reset
  end
end
