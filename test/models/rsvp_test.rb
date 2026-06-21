require "test_helper"

class RsvpTest < ActiveSupport::TestCase
  test "supports the three RSVP statuses" do
    rsvp = rsvps(:member_maybe_film_night)

    assert_predicate rsvp, :maybe?
    assert rsvp.update(status: :attending)
    assert_predicate rsvp, :attending?
    assert rsvp.update(status: :not_attending)
    assert_predicate rsvp, :not_attending?
  end

  test "allows one RSVP per membership and event" do
    duplicate = Rsvp.new(
      event: events(:upcoming_film_night),
      membership: memberships(:film_member),
      status: :attending
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:membership_id], "has already been taken"
  end

  test "membership must belong to the event organization" do
    garden_event = Event.create!(
      organization: organizations(:garden_club),
      created_by: users(:owner),
      title: "Garden work day",
      starts_at: 1.week.from_now
    )
    rsvp = Rsvp.new(
      event: garden_event,
      membership: memberships(:film_member),
      status: :attending
    )

    assert_not rsvp.valid?
    assert_includes rsvp.errors[:membership], "must belong to the event organization"
  end

  test "only attending RSVPs count toward capacity" do
    event = events(:upcoming_film_night)
    event.update!(capacity: 1)

    assert_equal 1, event.attending_count
    assert_predicate event, :full?
  end

  test "reports when an RSVP deadline has passed" do
    event = events(:upcoming_film_night)
    event.update!(rsvp_deadline: 1.minute.ago)

    assert_predicate event, :rsvp_deadline_passed?
  end
end
