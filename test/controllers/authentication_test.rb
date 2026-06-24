require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "signs up a user and starts a session" do
    assert_difference("User.count") do
      post users_path, params: { user: { name: "Sam Rivera", email_address: "sam@example.com", password: "password1234", password_confirmation: "password1234" } }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_select "h1", text: "Your organizations"
    assert_select ".eyebrow", text: /Welcome, Sam Rivera/
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

  test "returns to protected internal get after sign in" do
    get organization_members_path(organizations(:film_society))

    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:owner).email_address, password: "password1234" }

    assert_redirected_to organization_members_path(organizations(:film_society))
  end

  test "does not replay protected non-get requests after sign in" do
    post organizations_path, params: { organization: { name: "Replay Club" } }

    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:owner).email_address, password: "password1234" }

    assert_redirected_to root_path
    assert_not Organization.exists?(name: "Replay Club")
  end

  test "shows an accessible note when sign-in fails" do
    post session_path, params: { email_address: users(:owner).email_address, password: "incorrect-password" }

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: "That email and password did not match."
  end

  test "connects sign-in and account creation paths" do
    get new_session_path
    assert_select "aside[aria-label='About member access'] a[href=?]", new_user_path, text: /Create your account/
    assert_select "input[aria-describedby='signin-email-hint']"
    assert_select "p", text: "Demo workspace"
    assert_select "dd", text: "demo-owner@example.test"
    assert_select "dd", text: "tabled-demo-password"

    get new_user_path
    assert_select "aside[aria-label='About Tabled accounts'] a[href=?]", new_session_path, text: /member sign-in/
    assert_select "input[aria-describedby='account-name-hint']"
    assert_select "input[aria-describedby='account-email-hint']"
    assert_select "input[aria-describedby='account-password-hint']"
  end
end
