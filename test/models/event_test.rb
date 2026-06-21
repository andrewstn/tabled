require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "requires a title and start time" do
    event = Event.new(organization: organizations(:film_society), created_by: users(:owner))

    assert_not event.valid?
    assert_includes event.errors[:title], "can't be blank"
    assert_includes event.errors[:starts_at], "can't be blank"
  end

  test "end time must be after start time" do
    event = events(:upcoming_film_night)
    event.ends_at = event.starts_at

    assert_not event.valid?
    assert_includes event.errors[:ends_at], "must be after the start time"
  end

  test "capacity must be a positive whole number" do
    event = events(:upcoming_film_night)

    event.capacity = 0
    assert_not event.valid?

    event.capacity = 1.5
    assert_not event.valid?
  end

  test "RSVP deadline cannot be after the start time" do
    event = events(:upcoming_film_night)
    event.rsvp_deadline = event.starts_at + 1.minute

    assert_not event.valid?
    assert_includes event.errors[:rsvp_deadline], "must be on or before the start time"
  end

  test "upcoming and past scopes order gatherings around the current time" do
    upcoming_later = events(:upcoming_film_night).dup
    upcoming_later.title = "Later gathering"
    upcoming_later.starts_at = 4.days.from_now
    upcoming_later.ends_at = nil
    upcoming_later.rsvp_deadline = nil
    upcoming_later.save!

    assert_equal [ events(:upcoming_film_night), upcoming_later ], Event.upcoming.to_a
    assert_equal [ events(:past_planning_table) ], Event.past.to_a
  end
end
