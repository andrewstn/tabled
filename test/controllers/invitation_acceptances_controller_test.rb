require "test_helper"

class InvitationAcceptancesControllerTest < ActionDispatch::IntegrationTest
  test "accepted invitation creates membership for existing user" do
    invitation = create_invitation(organization: organizations(:garden_club), email: users(:member).email_address)
    sign_in_as(users(:member))

    assert_difference("Membership.count") do
      patch invitation_acceptance_path(invitation.token)
    end

    assert_redirected_to organization_path(organizations(:garden_club))
    assert invitation.reload.accepted?
    assert_equal "member", users(:member).memberships.find_by!(organization: organizations(:garden_club)).role
  end

  test "expired invitation cannot be accepted" do
    invitation = invitations(:expired_member)
    user = User.create!(name: "Expired Invitee", email_address: invitation.email, password: "password1234")
    sign_in_as(user)

    assert_no_difference("Membership.count") do
      patch invitation_acceptance_path("expired-member-token")
    end

    assert_redirected_to invitation_acceptance_path("expired-member-token")
    assert_not invitation.reload.accepted?
  end

  test "revoked invitation cannot be accepted" do
    invitation = invitations(:revoked_member)
    user = User.create!(name: "Revoked Invitee", email_address: invitation.email, password: "password1234")
    sign_in_as(user)

    assert_no_difference("Membership.count") do
      patch invitation_acceptance_path("revoked-member-token")
    end

    assert_not invitation.reload.accepted?
  end

  test "invitation cannot create a duplicate membership" do
    invitation = create_invitation(organization: organizations(:garden_club), email: users(:member).email_address)
    Membership.create!(organization: organizations(:garden_club), user: users(:member), role: :member)
    sign_in_as(users(:member))

    assert_no_difference("Membership.count") do
      patch invitation_acceptance_path(invitation.token)
    end

    assert_not invitation.reload.accepted?
  end

  test "new invitee creates account and joins organization" do
    invitation = create_invitation(organization: organizations(:garden_club), email: "new.student@example.com")

    assert_difference([ "User.count", "Membership.count" ]) do
      post users_path, params: {
        invitation_token: invitation.token,
        user: {
          name: "New Student",
          email_address: invitation.email,
          password: "password1234",
          password_confirmation: "password1234"
        }
      }
    end

    assert_redirected_to organization_path(organizations(:garden_club))
    assert invitation.reload.accepted?
  end

  test "new invitee is led to a prefilled account form" do
    invitation = create_invitation(organization: organizations(:garden_club), email: "prefilled.student@example.com")

    get invitation_acceptance_path(invitation.token)
    assert_select "a[href=?]", new_user_path(invitation_token: invitation.token), text: "Create account"

    get new_user_path(invitation_token: invitation.token)
    assert_select "input[type='email'][value=?]", invitation.email
    assert_select "input[name='invitation_token'][value=?]", invitation.token
  end

  test "user with a different email cannot accept" do
    invitation = create_invitation(organization: organizations(:garden_club), email: "someone.else@example.com")
    sign_in_as(users(:member))

    assert_no_difference("Membership.count") do
      patch invitation_acceptance_path(invitation.token)
    end

    assert_response :forbidden
  end

  private

  def create_invitation(organization:, email:)
    Invitation.create!(organization: organization, invited_by: users(:owner), email: email, role: :member)
  end

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
