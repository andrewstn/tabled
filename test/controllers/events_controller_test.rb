require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  test "organization member can view upcoming and past gatherings" do
    sign_in_as(users(:member))

    get organization_events_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Gatherings"
    assert_select "h2", "Upcoming gatherings"
    assert_select "h2", "Past gatherings"
    assert_select "h3", events(:upcoming_film_night).title
    assert_select "h3", events(:past_planning_table).title
    assert_select ".role-tag", text: "Maybe"
  end

  test "non-member cannot view organization gatherings" do
    sign_in_as(users(:member))

    get organization_events_path(organizations(:garden_club))

    assert_response :not_found
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
