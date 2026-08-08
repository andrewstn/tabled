require "test_helper"

class AnnouncementDeliveryTest < ActiveSupport::TestCase
  test "sent delivery requires sent at" do
    delivery = AnnouncementDelivery.new(
      announcement: announcements(:pinned_all_members),
      membership: memberships(:film_member),
      user: users(:member),
      email: users(:member).email_address,
      status: :sent
    )

    assert_not delivery.valid?
    assert_includes delivery.errors[:sent_at], "must be set for sent deliveries"
  end

  test "skipped delivery requires reason" do
    delivery = AnnouncementDelivery.new(
      announcement: announcements(:pinned_all_members),
      membership: memberships(:film_member),
      user: users(:member),
      email: users(:member).email_address,
      status: :skipped
    )

    assert_not delivery.valid?
    assert_includes delivery.errors[:skipped_reason], "must be set for skipped deliveries"
  end

  test "delivery is unique per announcement and membership" do
    AnnouncementDelivery.create!(
      announcement: announcements(:pinned_all_members),
      membership: memberships(:film_member),
      user: users(:member),
      email: users(:member).email_address,
      status: :sent,
      sent_at: Time.current
    )
    duplicate = AnnouncementDelivery.new(
      announcement: announcements(:pinned_all_members),
      membership: memberships(:film_member),
      user: users(:member),
      email: users(:member).email_address,
      status: :sent,
      sent_at: Time.current
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:membership_id], "has already been taken"
  end
end
