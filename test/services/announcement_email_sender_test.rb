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

  test "officers announcement emails organizer roles only" do
    memberships(:film_member).update!(role: :member)
    announcement = announcements(:officer_notes)
    announcement.update!(status: :published)

    assert_emails 1 do
      AnnouncementEmailSender.new(announcement: announcement).deliver
    end

    assert_equal [ users(:owner).email_address ], ActionMailer::Base.deliveries.last.to
  end
end
