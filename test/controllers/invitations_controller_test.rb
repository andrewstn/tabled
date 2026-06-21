require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  test "owner can invite a member with normalized email" do
    sign_in_as(users(:owner))

    assert_emails 1 do
      assert_difference("Invitation.count") do
        post organization_invitations_path(organizations(:film_society)),
          params: { invitation: { email: " NEW.PERSON@Example.com ", role: "member" } }
      end
    end

    invitation = Invitation.order(:created_at).last
    assert_equal "new.person@example.com", invitation.email
    assert_equal users(:owner), invitation.invited_by
    assert invitation.pending?
  end

  test "officer can invite a coordinator" do
    memberships(:film_member).update!(role: :officer)
    sign_in_as(users(:member))

    assert_difference("Invitation.count") do
      post organization_invitations_path(organizations(:film_society)),
        params: { invitation: { email: "coordinator@example.com", role: "coordinator" } }
    end
  end

  test "member cannot invite a member" do
    sign_in_as(users(:member))

    assert_no_difference("Invitation.count") do
      post organization_invitations_path(organizations(:film_society)),
        params: { invitation: { email: "another@example.com", role: "member" } }
    end

    assert_response :forbidden
  end

  test "officer cannot invite an owner" do
    memberships(:film_member).update!(role: :officer)
    sign_in_as(users(:member))

    assert_no_difference("Invitation.count") do
      post organization_invitations_path(organizations(:film_society)),
        params: { invitation: { email: "owner@example.com", role: "owner" } }
    end

    assert_response :forbidden
  end

  test "duplicate pending invitation is rejected" do
    sign_in_as(users(:owner))

    assert_no_difference("Invitation.count") do
      post organization_invitations_path(organizations(:film_society)),
        params: { invitation: { email: invitations(:pending_member).email.upcase, role: "member" } }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /already has a pending invitation/
  end

  test "current member cannot be invited again" do
    sign_in_as(users(:owner))

    assert_no_difference("Invitation.count") do
      post organization_invitations_path(organizations(:film_society)),
        params: { invitation: { email: users(:member).email_address, role: "member" } }
    end

    assert_response :unprocessable_entity
  end

  test "owner can revoke a pending invitation" do
    sign_in_as(users(:owner))

    delete organization_invitation_path(organizations(:film_society), invitations(:pending_member))

    assert_redirected_to organization_invitations_path(organizations(:film_society))
    assert invitations(:pending_member).reload.revoked?
  end

  test "member cannot revoke an invitation" do
    sign_in_as(users(:member))

    delete organization_invitation_path(organizations(:film_society), invitations(:pending_member))

    assert_response :forbidden
    assert_not invitations(:pending_member).reload.revoked?
  end

  test "invitation list has a useful empty state" do
    organizations(:film_society).invitations.destroy_all
    sign_in_as(users(:owner))

    get organization_invitations_path(organizations(:film_society))

    assert_response :success
    assert_select "p", text: "No invitations yet."
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
