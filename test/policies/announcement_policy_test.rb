require "test_helper"

class AnnouncementPolicyTest < ActiveSupport::TestCase
  test "owners can manage and publish announcements" do
    policy = AnnouncementPolicy.new(users(:owner), organizations(:film_society), announcements(:officer_notes))

    assert_predicate policy, :show?
    assert_predicate policy, :create?
    assert_predicate policy, :update?
    assert_predicate policy, :destroy?
    assert_predicate policy, :publish?
  end

  test "officers can manage announcements" do
    memberships(:film_member).update!(role: :officer)
    policy = AnnouncementPolicy.new(users(:member), organizations(:film_society), announcements(:officer_notes))

    assert_predicate policy, :create?
    assert_predicate policy, :update?
    assert_predicate policy, :publish?
  end

  test "members can read published all member announcements but not drafts" do
    published_policy = AnnouncementPolicy.new(users(:member), organizations(:film_society), announcements(:pinned_all_members))
    draft_policy = AnnouncementPolicy.new(users(:member), organizations(:film_society), announcements(:officer_notes))

    assert_predicate published_policy, :show?
    assert_not draft_policy.show?
    assert_not published_policy.create?
  end

  test "members cannot read officers-only announcements" do
    announcement = announcements(:officer_notes)
    announcement.update!(status: :published)

    assert_not AnnouncementPolicy.new(users(:member), organizations(:film_society), announcement).show?
  end

  test "coordinators can read officers-only posts but cannot manage them" do
    memberships(:film_member).update!(role: :coordinator)
    announcement = announcements(:officer_notes)
    announcement.update!(status: :published)
    policy = AnnouncementPolicy.new(users(:member), organizations(:film_society), announcement)

    assert_predicate policy, :show?
    assert_not policy.create?
    assert_not policy.update?
  end

  test "non-members cannot read or manage announcements" do
    policy = AnnouncementPolicy.new(users(:member), organizations(:garden_club), announcements(:pinned_all_members))

    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.create?
  end
end
