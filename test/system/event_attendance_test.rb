require "application_system_test_case"

class EventAttendanceTest < ApplicationSystemTestCase
  test "marking attendance keeps the organizer at the member row" do
    10.times do |index|
      user = User.create!(
        name: "Roster Member #{index}",
        email_address: "roster-member-#{index}@example.test",
        password: "password1234"
      )
      Membership.create!(organization: organizations(:film_society), user: user, role: :member)
    end
    target = organizations(:film_society).memberships.joins(:user).order("users.name").last
    sign_in_as(users(:owner))
    visit organization_event_attendance_path(organizations(:film_society), events(:upcoming_film_night))

    frame_selector = "#attendance-member-#{target.id}"
    execute_script("document.querySelector('#{frame_selector}').scrollIntoView({ block: 'center' })")
    scroll_before = page.evaluate_script("window.scrollY")

    within frame_selector do
      click_button "Present"
      assert_selector ".role-tag", text: "Present"
      assert_text "Attendance updated."
    end

    scroll_after = page.evaluate_script("window.scrollY")
    assert_operator scroll_before, :>, 0
    assert_operator scroll_after, :>, 0
    assert_operator (scroll_after - scroll_before).abs, :<, 150
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "Member email", with: user.email_address
    fill_in "Password", with: "password1234"
    click_on "Sign in"
    assert_text "Signed in as #{user.name}."
  end
end
