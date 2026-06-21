require "test_helper"

class RsvpsControllerTest < ActionDispatch::IntegrationTest
  test "member can create their own RSVP in their organization" do
    rsvps(:member_maybe_film_night).destroy!
    sign_in_as(users(:member))

    assert_difference("Rsvp.count") do
      post organization_event_rsvp_path(organizations(:film_society), events(:upcoming_film_night)), params: {
        rsvp: { status: "attending" }
      }
    end

    assert_redirected_to organization_event_path(organizations(:film_society), events(:upcoming_film_night))
    assert_predicate memberships(:film_member).rsvps.find_by(event: events(:upcoming_film_night)), :attending?
  end

  test "member can update their own RSVP" do
    sign_in_as(users(:member))

    assert_no_difference("Rsvp.count") do
      patch organization_event_rsvp_path(organizations(:film_society), events(:upcoming_film_night)), params: {
        rsvp: { status: "not_attending" }
      }
    end

    assert_predicate rsvps(:member_maybe_film_night).reload, :not_attending?
  end

  test "member cannot RSVP to another organization event" do
    garden_event = Event.create!(organization: organizations(:garden_club), created_by: users(:owner), title: "Work day", starts_at: 1.week.from_now)
    sign_in_as(users(:member))

    assert_no_difference("Rsvp.count") do
      post organization_event_rsvp_path(organizations(:garden_club), garden_event), params: { rsvp: { status: "attending" } }
    end

    assert_response :not_found
  end

  test "capacity blocks another attending member RSVP" do
    event = events(:upcoming_film_night)
    event.update!(capacity: 1)
    sign_in_as(users(:member))

    patch organization_event_rsvp_path(organizations(:film_society), event), params: { rsvp: { status: "attending" } }

    assert_redirected_to organization_event_path(organizations(:film_society), event)
    assert_equal "This gathering is full", flash[:alert]
    assert_predicate rsvps(:member_maybe_film_night).reload, :maybe?
  end

  test "deadline blocks a regular member RSVP" do
    event = events(:upcoming_film_night)
    event.update!(rsvp_deadline: 1.minute.ago)
    sign_in_as(users(:member))

    patch organization_event_rsvp_path(organizations(:film_society), event), params: { rsvp: { status: "attending" } }

    assert_equal "RSVPs are closed for this gathering", flash[:alert]
    assert_predicate rsvps(:member_maybe_film_night).reload, :maybe?
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
