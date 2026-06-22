require "test_helper"

class AnnouncementTest < ActiveSupport::TestCase
  test "requires title body audience status organization and author" do
    announcement = Announcement.new

    assert_not announcement.valid?
    assert_includes announcement.errors[:title], "can't be blank"
    assert_includes announcement.errors[:body], "can't be blank"
    assert_includes announcement.errors[:organization], "must exist"
    assert_includes announcement.errors[:author], "must exist"
    assert_includes announcement.errors[:audience], "is not included in the list"
  end

  test "publishing sets published at" do
    announcement = Announcement.create!(
      organization: organizations(:film_society),
      author: users(:owner),
      title: "Room update",
      body: "We are meeting in room 214.",
      audience: :all_members,
      status: :published
    )

    assert_not_nil announcement.published_at
  end

  test "draft does not retain a published timestamp" do
    announcement = announcements(:pinned_all_members)

    announcement.update!(status: :draft)

    assert_nil announcement.published_at
  end

  test "bulletin ordering puts pinned announcements first" do
    ordered = organizations(:film_society).announcements.published.bulletin_order

    assert_equal announcements(:pinned_all_members), ordered.first
  end

  test "published visibility follows membership audience" do
    member_visible = organizations(:film_society).announcements.published_for(memberships(:film_member))
    owner_visible = organizations(:film_society).announcements.published_for(memberships(:film_owner))

    assert_includes member_visible, announcements(:pinned_all_members)
    assert_not_includes member_visible, announcements(:officer_notes)
    assert_includes owner_visible, announcements(:pinned_all_members)
  end
end
