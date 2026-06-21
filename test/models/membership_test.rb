require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "accepts only supported roles" do
    membership = Membership.new(user: users(:owner), organization: organizations(:garden_club), role: "visitor")

    assert_not membership.valid?
    assert_includes membership.errors[:role], "is not included in the list"
  end

  test "prevents duplicate organization membership" do
    duplicate = Membership.new(user: users(:owner), organization: organizations(:film_society), role: :member)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
