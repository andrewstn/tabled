require "test_helper"

class AnnouncementMailerTest < ActionMailer::TestCase
  test "announcement email includes organization author body and link" do
    announcement = announcements(:pinned_all_members)
    recipient = users(:member)

    mail = AnnouncementMailer.with(announcement: announcement, recipient: recipient).announcement

    assert_equal [ recipient.email_address ], mail.to
    assert_equal "[Buckeye Film Society] New announcement: First Friday Film Night details", mail.subject
    assert_includes mail.text_part.body.decoded, announcement.body
    assert_includes mail.text_part.body.decoded, announcement.author.name
    announcement_url = Rails.application.routes.url_helpers.organization_announcement_url(
      announcement.organization,
      announcement,
      host: "example.com"
    )
    assert_includes mail.text_part.body.decoded, announcement_url
  end
end
