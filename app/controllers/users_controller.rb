class UsersController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create]

  def new
    redirect_to root_path if authenticated?
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: "Your member account is ready."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: %i[name email_address password password_confirmation])
  end
end
