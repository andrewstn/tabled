require "test_helper"

class OwnershipTransferTest < ActiveSupport::TestCase
  test "promotes an existing member to owner" do
    transfer = OwnershipTransfer.new(
      organization: organizations(:film_society),
      target_membership_id: memberships(:film_member).id
    )

    assert transfer.transfer
    assert_predicate memberships(:film_member).reload, :owner?
  end

  test "does not transfer to non-members" do
    Membership.create!(organization: organizations(:garden_club), user: users(:owner), role: :member)
    transfer = OwnershipTransfer.new(
      organization: organizations(:film_society),
      target_membership_id: users(:owner).memberships.find_by(organization: organizations(:garden_club)).id
    )

    assert_not transfer.transfer
  end
end
