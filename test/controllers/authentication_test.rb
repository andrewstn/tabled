require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "signs up a user and starts a session" do
    assert_difference("User.count") do
      post users_path, params: { user: { name: "Sam Rivera", email_address: "sam@example.com", password: "password1234", password_confirmation: "password1234" } }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_select "h1", text: /Welcome, Sam Rivera/
  end

  test "signs in and signs out" do
    post session_path, params: { email_address: users(:owner).email_address, password: "password1234" }
    assert_redirected_to root_path

    delete session_path
    assert_redirected_to new_session_path
  end

  test "protects authenticated pages" do
    get root_path

    assert_redirected_to new_session_path
  end
end
