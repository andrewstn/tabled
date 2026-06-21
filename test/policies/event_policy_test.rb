require "test_helper"

class EventPolicyTest < ActiveSupport::TestCase
  test "members can view events but cannot manage them" do
    policy = EventPolicy.new(users(:member), organizations(:film_society), events(:upcoming_film_night))

    assert_predicate policy, :show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.view_roster?
  end

  test "owners can manage events and view rosters" do
    policy = EventPolicy.new(users(:owner), organizations(:film_society), events(:upcoming_film_night))

    assert_predicate policy, :create?
    assert_predicate policy, :update?
    assert_predicate policy, :destroy?
    assert_predicate policy, :view_roster?
  end

  test "coordinators can edit events but cannot delete them" do
    memberships(:film_member).update!(role: :coordinator)
    policy = EventPolicy.new(users(:member), organizations(:film_society), events(:upcoming_film_night))

    assert_predicate policy, :create?
    assert_predicate policy, :update?
    assert_not policy.destroy?
    assert_predicate policy, :view_roster?
  end
end
