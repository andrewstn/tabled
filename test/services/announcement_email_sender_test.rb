require "test_helper"

class AnnouncementEmailSenderTest < ActionMailer::TestCase
  test "draft is not emailed" do
    announcement = announcements(:officer_notes)

    assert_no_emails do
      assert_not AnnouncementEmailSender.new(announcement: announcement).deliver
    end
    assert_nil announcement.reload.emailed_at
  end

  test "all-member announcement emails organization members only" do
    outsider = User.create!(name: "Outside Student", email_address: "outside@example.test", password: "password1234")
    Membership.create!(organization: organizations(:garden_club), user: outsider, role: :owner)
    announcement = announcements(:pinned_all_members)

    assert_emails organizations(:film_society).memberships.count do
      AnnouncementEmailSender.new(announcement: announcement).deliver
    end

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)
    assert_includes recipients, users(:member).email_address
    assert_not_includes recipients, outsider.email_address
    assert_not_nil announcement.reload.emailed_at
  end

  test "members with announcement emails disabled are skipped" do
    memberships(:film_member).update!(announcement_emails_enabled: false)
    announcement = announcements(:pinned_all_members)

    assert_emails 1 do
      AnnouncementEmailSender.new(announcement: announcement).deliver
    end

    sent = announcement.announcement_deliveries.find_by!(membership: memberships(:film_owner))
    skipped = announcement.announcement_deliveries.find_by!(membership: memberships(:film_member))
    assert_predicate sent, :sent?
    assert_predicate skipped, :skipped?
    assert_equal "announcement_emails_disabled", skipped.skipped_reason
  end

  test "officers announcement emails organizer roles only" do
    memberships(:film_member).update!(role: :member)
    announcement = announcements(:officer_notes)
    announcement.update!(status: :published)

    assert_emails 1 do
      AnnouncementEmailSender.new(announcement: announcement).deliver
    end

    assert_equal [ users(:owner).email_address ], ActionMailer::Base.deliveries.last.to
  end

  test "event rsvps announcement emails only rsvp audience" do
    outsider = User.create!(name: "No RSVP", email_address: "no-rsvp-mail@example.test", password: "password1234")
    Membership.create!(organization: organizations(:film_society), user: outsider, role: :member)
    announcement = Announcement.create!(
      organization: organizations(:film_society),
      author: users(:owner),
      title: "RSVP email",
      body: "For members with RSVPs.",
      audience: :event_rsvps,
      target_event: events(:upcoming_film_night),
      status: :published
    )

    assert_emails 2 do
      AnnouncementEmailSender.new(announcement: announcement).deliver
    end

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)
    assert_includes recipients, users(:owner).email_address
    assert_includes recipients, users(:member).email_address
    assert_not_includes recipients, outsider.email_address
    assert_equal 2, announcement.announcement_deliveries.sent.count
  end

  test "event attendees announcement emails only present and late attendance audience" do
    announcement = Announcement.create!(
      organization: organizations(:film_society),
      author: users(:owner),
      title: "Attendee email",
      body: "For checked-in attendees.",
      audience: :event_attendees,
      target_event: events(:past_planning_table),
      status: :published
    )

    assert_emails 2 do
      AnnouncementEmailSender.new(announcement: announcement).deliver
    end

    assert_equal [ users(:owner).email_address, users(:member).email_address ].sort, ActionMailer::Base.deliveries.flat_map(&:to).sort
  end

  test "duplicate delivery call does not send duplicate emails" do
    announcement = announcements(:pinned_all_members)

    assert_emails organizations(:film_society).memberships.count do
      AnnouncementEmailSender.new(announcement: announcement).deliver
    end
    assert_no_emails do
      AnnouncementEmailSender.new(announcement: announcement).deliver
    end
  end

  test "delivery summary counts are recorded" do
    memberships(:film_member).update!(announcement_emails_enabled: false)
    announcement = announcements(:pinned_all_members)

    AnnouncementEmailSender.new(announcement: announcement).deliver

    assert_equal 1, announcement.announcement_deliveries.sent.count
    assert_equal 1, announcement.announcement_deliveries.skipped.count
  end
end
