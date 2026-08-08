class AccountSettingsController < ApplicationController
  def show
    @user = current_user
  end

  def update
    @user = current_user
    attributes = account_params.to_h.symbolize_keys
    current_password = attributes.delete(:current_password).to_s
    password_changing = attributes[:password].present? || attributes[:password_confirmation].present?
    email_changing = attributes.key?(:email_address) && email_changing?(attributes[:email_address])

    attributes.except!(:password, :password_confirmation) unless password_changing

    if (email_changing || password_changing) && !@user.authenticate(current_password)
      @user.assign_attributes(attributes.except(:password, :password_confirmation))
      @user.errors.add(:current_password, "is required to change your email or password")
      return render :show, status: :unprocessable_entity
    end

    if @user.update(attributes)
      redirect_to account_settings_path, notice: "Account settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.expect(user: %i[name email_address current_password password password_confirmation])
  end

  def email_changing?(email_address)
    email_address.to_s.strip.downcase != @user.email_address
  end
end
