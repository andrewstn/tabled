class AccountSettingsController < ApplicationController
  def show
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(account_params)
      redirect_to account_settings_path, notice: "Account settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.expect(user: [ :name ])
  end
end
