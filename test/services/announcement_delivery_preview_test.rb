require "test_helper"

class AnnouncementDeliveryPreviewTest < ActiveSupport::TestCase
  test "counts visible recipients and preference skips" do
    memberships(:film_member).update!(announcement_emails_enabled: false)
    preview = AnnouncementDeliveryPreview.new(announcements(:pinned_all_members))

    assert_equal 2, preview.visible_count
    assert_equal 1, preview.email_recipient_count
    assert_equal 1, preview.skipped_for_preferences_count
  end
end
