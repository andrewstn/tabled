require "test_helper"

class OwnershipTransfersControllerTest < ActionDispatch::IntegrationTest
  test "owner can transfer ownership to existing member" do
    sign_in_as(users(:owner))

    assert_difference("ActivityLogEntry.count") do
      patch organization_ownership_transfer_path(organizations(:film_society)), params: {
        membership_id: memberships(:film_member).id
      }
    end

    assert_redirected_to edit_organization_path(organizations(:film_society))
    assert_predicate memberships(:film_member).reload, :owner?
    assert_predicate memberships(:film_owner).reload, :owner?
    assert_equal "ownership.transferred", ActivityLogEntry.order(:created_at).last.action
  end

  test "non-owner cannot transfer ownership" do
    memberships(:film_member).update!(role: :officer)
    sign_in_as(users(:member))

    patch organization_ownership_transfer_path(organizations(:film_society)), params: {
      membership_id: memberships(:film_owner).id
    }

    assert_response :forbidden
  end

  test "ownership cannot be transferred to a non-member" do
    other_membership = Membership.create!(organization: organizations(:garden_club), user: users(:owner), role: :member)
    sign_in_as(users(:owner))

    assert_no_difference("ActivityLogEntry.count") do
      patch organization_ownership_transfer_path(organizations(:film_society)), params: {
        membership_id: other_membership.id
      }
    end

    assert_redirected_to edit_organization_path(organizations(:film_society))
    assert_equal "Choose a current member to make an owner.", flash[:alert]
  end

  test "owner settings show transfer ownership form" do
    sign_in_as(users(:owner))

    get edit_organization_path(organizations(:film_society))

    assert_response :success
    assert_select "h3", "Transfer ownership"
    assert_select "form[action=?]", organization_ownership_transfer_path(organizations(:film_society))
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
