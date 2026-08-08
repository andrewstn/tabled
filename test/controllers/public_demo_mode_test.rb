require "test_helper"

class PublicDemoModeTest < ActionDispatch::IntegrationTest
  setup do
    @previous_public_demo = ENV["TABLED_PUBLIC_DEMO"]
    ENV["TABLED_PUBLIC_DEMO"] = "true"
    users(:owner).update!(demo_account: true)
    sign_in_as(users(:owner))
  end

  teardown do
    ENV["TABLED_PUBLIC_DEMO"] = @previous_public_demo
  end

  test "demo account can browse organization workspace" do
    get organization_path(organizations(:film_society))

    assert_response :success
    assert_select "strong", text: "Public demo mode:"
    assert_select "h1", text: organizations(:film_society).name
  end

  test "demo account cannot update account settings" do
    patch account_settings_path, params: {
      user: {
        name: "Changed Demo User",
        email_address: users(:owner).email_address,
        current_password: "password1234"
      }
    }

    assert_redirected_to root_path
    assert_equal "Alex Morgan", users(:owner).reload.name
    assert_equal "Public demo mode keeps this workspace read-only so it stays intact for everyone.", flash[:alert]
  end

  test "demo account cannot create organization records" do
    assert_no_difference("Organization.count") do
      post organizations_path, params: {
        organization: {
          name: "Vandal Club",
          description: "This should not be created."
        }
      }
    end

    assert_redirected_to root_path
  end

  test "demo account can sign out" do
    delete session_path

    assert_redirected_to new_session_path
  end

  test "non demo account can still mutate in public demo mode" do
    users(:owner).update!(demo_account: false)

    assert_difference("Organization.count", 1) do
      post organizations_path, params: {
        organization: {
          name: "Campus Debate Society",
          description: "A normal signed-in user can still use the app."
        }
      }
    end
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
