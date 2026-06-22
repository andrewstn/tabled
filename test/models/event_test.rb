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

  test "check in code is stored as a digest and matched case insensitively" do
    event = events(:upcoming_film_night)
    code = event.regenerate_check_in_code
    event.save!

    assert_not_equal code, event.check_in_code_digest
    assert event.valid_check_in_code?(code.downcase)
    assert_not event.valid_check_in_code?("WRONG1")
  end

  test "check in window must close after it opens" do
    event = events(:upcoming_film_night)
    event.check_in_opens_at = 1.hour.from_now
    event.check_in_closes_at = Time.current

    assert_not event.valid?
    assert_includes event.errors[:check_in_closes_at], "must be after check-in opens"
  end
end
