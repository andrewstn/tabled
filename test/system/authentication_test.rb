require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "a member signs in and opens their organizations" do
    visit new_session_path

    fill_in "Member email", with: users(:owner).email_address
    fill_in "Password", with: "password1234"
    click_on "Sign in"

    assert_text "Signed in as Alex Morgan."
    assert_selector "h1", text: "Your organizations"
  end
end
