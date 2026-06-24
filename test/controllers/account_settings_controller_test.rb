require "test_helper"

class AccountSettingsControllerTest < ActionDispatch::IntegrationTest
  test "user can view account settings" do
    sign_in_as(users(:member))

    get account_settings_path

    assert_response :success
    assert_select "h1", "Account settings"
    assert_select "p", text: "Update the name, email, and password used across your organizations."
    assert_select "input[name='user[email_address]']"
    assert_select "input[name='user[current_password]']"
    assert_select "input[name='user[password]']"
    assert_select "input[name='user[password_confirmation]']"
  end

  test "user can update their own name" do
    sign_in_as(users(:member))

    patch account_settings_path, params: { user: { name: "Jordan Riley" } }

    assert_redirected_to account_settings_path
    assert_equal "Jordan Riley", users(:member).reload.name
  end

  test "user can update their email with their current password" do
    sign_in_as(users(:member))

    patch account_settings_path, params: {
      user: {
        name: users(:member).name,
        email_address: "new-jordan@example.test",
        current_password: "password1234"
      }
    }

    assert_redirected_to account_settings_path
    assert_equal "new-jordan@example.test", users(:member).reload.email_address
  end

  test "email update requires current password" do
    sign_in_as(users(:member))

    patch account_settings_path, params: {
      user: {
        name: users(:member).name,
        email_address: "blocked-jordan@example.test",
        current_password: "wrong-password"
      }
    }

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Current password is required to change your email or password/
    assert_not_equal "blocked-jordan@example.test", users(:member).reload.email_address
  end

  test "user can update their password with their current password" do
    sign_in_as(users(:member))

    patch account_settings_path, params: {
      user: {
        name: users(:member).name,
        email_address: users(:member).email_address,
        current_password: "password1234",
        password: "new-password-1234",
        password_confirmation: "new-password-1234"
      }
    }

    assert_redirected_to account_settings_path

    delete session_path
    post session_path, params: { email_address: users(:member).email_address, password: "new-password-1234" }
    assert_redirected_to root_path
  end

  test "password update requires current password" do
    sign_in_as(users(:member))

    patch account_settings_path, params: {
      user: {
        name: users(:member).name,
        email_address: users(:member).email_address,
        current_password: "wrong-password",
        password: "new-password-1234",
        password_confirmation: "new-password-1234"
      }
    }

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Current password is required to change your email or password/
    assert users(:member).reload.authenticate("password1234")
  end

  test "password update validates new password" do
    sign_in_as(users(:member))

    patch account_settings_path, params: {
      user: {
        name: users(:member).name,
        email_address: users(:member).email_address,
        current_password: "password1234",
        password: "short",
        password_confirmation: "short"
      }
    }

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Password is too short/
  end

  test "email update validates unique email" do
    sign_in_as(users(:member))

    patch account_settings_path, params: {
      user: {
        name: users(:member).name,
        email_address: users(:owner).email_address.upcase,
        current_password: "password1234"
      }
    }

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Email address has already been taken/
  end

  test "user cannot update another user account settings" do
    sign_in_as(users(:member))

    patch account_settings_path, params: { user_id: users(:owner).id, user: { name: "Not Owner" } }

    assert_not_equal "Not Owner", users(:owner).reload.name
    assert_equal "Not Owner", users(:member).reload.name
  end

  test "invalid account settings render errors" do
    sign_in_as(users(:member))

    patch account_settings_path, params: { user: { name: "" } }

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Name can't be blank/
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
