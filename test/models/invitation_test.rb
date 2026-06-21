require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "normalizes email and stores only a token digest" do
    invitation = Invitation.create!(
      organization: organizations(:garden_club),
      invited_by: users(:owner),
      email: " NEW.MEMBER@Example.com ",
      role: :member
    )

    assert_equal "new.member@example.com", invitation.email
    assert invitation.token.present?
    assert_equal 32, invitation.token.length
    assert_not_includes invitation.token, "="
    assert_not_equal invitation.token, invitation.token_digest
    assert_equal invitation, Invitation.find_by_token(invitation.token)
    assert_in_delta 7.days.from_now, invitation.expires_at, 2.seconds
  end

  test "finds a token copied with a quoted-printable soft-break marker" do
    invitation = Invitation.create!(
      organization: organizations(:garden_club),
      invited_by: users(:owner),
      email: "wrapped.link@example.com",
      role: :member
    )
    wrapped_token = invitation.token.dup.insert(20, "=")

    assert_equal invitation, Invitation.find_by_token(wrapped_token)
  end

  test "rejects duplicate unresolved invitations case insensitively" do
    duplicate = Invitation.new(
      organization: invitations(:pending_member).organization,
      invited_by: users(:owner),
      email: invitations(:pending_member).email.upcase,
      role: :member
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "already has a pending invitation"
  end

  test "reports invitation state" do
    assert invitations(:pending_member).pending?
    assert invitations(:expired_member).expired?
    assert_not invitations(:expired_member).pending?
    assert invitations(:revoked_member).revoked?
    assert_not invitations(:revoked_member).pending?
  end
end
