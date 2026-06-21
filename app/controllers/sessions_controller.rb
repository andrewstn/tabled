class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create]

  def new
    redirect_to root_path if authenticated?
  end

  def create
    user = User.authenticate_by(email_address: params[:email_address], password: params[:password])

    if user
      return_to = session[:return_to_after_authenticating]
      start_new_session_for(user)
      redirect_to return_to || root_path, notice: "Signed in as #{user.name}."
    else
      flash.now[:alert] = "That email and password did not match."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: "You’re signed out."
  end
end
