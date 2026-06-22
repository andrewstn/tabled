require "test_helper"

class EventCheckInSettingsControllerTest < ActionDispatch::IntegrationTest
  test "organizer can open check in with a new secure code" do
    sign_in_as(users(:owner))
    event = events(:upcoming_film_night)

    patch organization_event_check_in_settings_path(organizations(:film_society), event), params: { operation: "open", duration_minutes: 30 }

    assert_redirected_to organization_event_path(organizations(:film_society), event)
    assert_equal 6, flash[:check_in_code].length
    assert_predicate event.reload, :check_in_open?
    assert event.valid_check_in_code?(flash[:check_in_code])
    assert_not_equal flash[:check_in_code], event.check_in_code_digest
  end

  test "organizer can close and regenerate check in" do
    event = events(:upcoming_film_night)
    event.regenerate_check_in_code
    event.update!(check_in_opens_at: 1.minute.ago, check_in_closes_at: 1.hour.from_now)
    old_digest = event.check_in_code_digest
    sign_in_as(users(:owner))

    patch organization_event_check_in_settings_path(organizations(:film_society), event), params: { operation: "regenerate" }
    assert_not_equal old_digest, event.reload.check_in_code_digest

    patch organization_event_check_in_settings_path(organizations(:film_society), event), params: { operation: "close" }
    assert_equal :closed, event.reload.check_in_state
  end

  test "member cannot manage check in" do
    sign_in_as(users(:member))

    patch organization_event_check_in_settings_path(organizations(:film_society), events(:upcoming_film_night)), params: { operation: "open" }

    assert_response :forbidden
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
