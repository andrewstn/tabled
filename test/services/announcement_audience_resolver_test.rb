require "test_helper"

class AnnouncementAudienceResolverTest < ActiveSupport::TestCase
  test "all members audience includes current organization members only" do
    announcement = announcements(:pinned_all_members)

    memberships = AnnouncementAudienceResolver.new(announcement).memberships

    assert_includes memberships, memberships(:film_owner)
    assert_includes memberships, memberships(:film_member)
  end

  test "officers audience includes organizer roles" do
    memberships(:film_member).update!(role: :member)
    announcement = announcements(:officer_notes)

    memberships = AnnouncementAudienceResolver.new(announcement).memberships

    assert_includes memberships, memberships(:film_owner)
    assert_not_includes memberships, memberships(:film_member)
  end

  test "event rsvps audience includes members with any RSVP for target event" do
    announcement = Announcement.new(
      organization: organizations(:film_society),
      author: users(:owner),
      title: "RSVP update",
      body: "For everyone who answered.",
      audience: :event_rsvps,
      target_event: events(:upcoming_film_night)
    )

    memberships = AnnouncementAudienceResolver.new(announcement).memberships

    assert_includes memberships, memberships(:film_owner)
    assert_includes memberships, memberships(:film_member)
  end

  test "event attendees audience includes present and late members only" do
    announcement = Announcement.new(
      organization: organizations(:film_society),
      author: users(:owner),
      title: "Attendance update",
      body: "For checked-in attendees.",
      audience: :event_attendees,
      target_event: events(:past_planning_table)
    )

    memberships = AnnouncementAudienceResolver.new(announcement).memberships

    assert_includes memberships, memberships(:film_owner)
    assert_includes memberships, memberships(:film_member)
  end

  test "visible to requires membership in resolved audience" do
    announcement = Announcement.new(
      organization: organizations(:film_society),
      author: users(:owner),
      title: "Attendance update",
      body: "For checked-in attendees.",
      audience: :event_attendees,
      target_event: events(:past_planning_table)
    )
    outsider_membership = Membership.create!(organization: organizations(:garden_club), user: users(:owner), role: :member)

    resolver = AnnouncementAudienceResolver.new(announcement)

    assert resolver.visible_to?(memberships(:film_owner))
    assert_not resolver.visible_to?(outsider_membership)
  end
end
