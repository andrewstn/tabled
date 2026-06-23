require "test_helper"

class AccountSettingsControllerTest < ActionDispatch::IntegrationTest
  test "user can view account settings" do
    sign_in_as(users(:member))

    get account_settings_path

    assert_response :success
    assert_select "h1", "Account settings"
    assert_select "p", text: "Update the name used across your organizations."
  end

  test "user can update their own name" do
    sign_in_as(users(:member))

    patch account_settings_path, params: { user: { name: "Jordan Riley" } }

    assert_redirected_to account_settings_path
    assert_equal "Jordan Riley", users(:member).reload.name
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
