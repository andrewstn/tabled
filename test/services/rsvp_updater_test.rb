require "test_helper"

class RsvpUpdaterTest < ActiveSupport::TestCase
  test "capacity prevents another attending RSVP" do
    event = events(:upcoming_film_night)
    event.update!(capacity: 1)

    updater = RsvpUpdater.new(
      event: event,
      membership: memberships(:film_member),
      attributes: { status: :attending }
    )

    assert_not updater.save
    assert_includes updater.rsvp.errors[:base], "This gathering is full"
    assert_predicate rsvps(:member_maybe_film_night).reload, :maybe?
  end

  test "maybe and not attending do not use capacity" do
    event = events(:upcoming_film_night)
    event.update!(capacity: 1)
    member_rsvp = rsvps(:member_maybe_film_night)

    assert RsvpUpdater.new(event: event, membership: member_rsvp.membership, attributes: { status: :not_attending }).save
    assert_equal 1, event.attending_count
  end

  test "changing from attending frees a capacity place" do
    owner_rsvp = rsvps(:owner_attending_film_night)
    event = owner_rsvp.event
    event.update!(capacity: 1)

    assert RsvpUpdater.new(event: event, membership: owner_rsvp.membership, attributes: { status: :maybe }).save
    assert RsvpUpdater.new(event: event, membership: memberships(:film_member), attributes: { status: :attending }).save
  end

  test "deadline blocks a regular member" do
    event = events(:upcoming_film_night)
    event.update!(rsvp_deadline: 1.minute.ago)

    updater = RsvpUpdater.new(event: event, membership: memberships(:film_member), attributes: { status: :attending })

    assert_not updater.save
    assert_includes updater.rsvp.errors[:base], "RSVPs are closed for this gathering"
  end

  test "organizer override permits a late RSVP" do
    event = events(:upcoming_film_night)
    event.update!(rsvp_deadline: 1.minute.ago, capacity: 1)

    updater = RsvpUpdater.new(
      event: event,
      membership: memberships(:film_member),
      attributes: { status: :attending },
      override_limits: true
    )

    assert updater.save
  end
end
