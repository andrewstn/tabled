require "test_helper"

class AnnouncementTest < ActiveSupport::TestCase
  test "event targeted announcement requires target event" do
    announcement = Announcement.new(
      organization: organizations(:film_society),
      author: users(:owner),
      title: "RSVP note",
      body: "For event RSVPs.",
      audience: :event_rsvps
    )

    assert_not announcement.valid?
    assert_includes announcement.errors[:target_event], "must be selected for this audience"
  end

  test "target event must belong to same organization" do
    other_event = Event.create!(
      organization: organizations(:garden_club),
      created_by: users(:owner),
      title: "Garden night",
      starts_at: 1.day.from_now
    )
    announcement = Announcement.new(
      organization: organizations(:film_society),
      author: users(:owner),
      title: "Wrong event",
      body: "Wrong organization.",
      audience: :event_rsvps,
      target_event: other_event
    )

    assert_not announcement.valid?
    assert_includes announcement.errors[:target_event], "must belong to this organization"
  end

  test "non-event audience does not require target event" do
    announcement = Announcement.new(
      organization: organizations(:film_society),
      author: users(:owner),
      title: "General note",
      body: "For everyone.",
      audience: :all_members
    )

    assert_predicate announcement, :valid?
  end
end
