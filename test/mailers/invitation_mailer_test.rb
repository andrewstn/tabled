require "test_helper"

class InvitationMailerTest < ActionMailer::TestCase
  test "invitation email includes organization, inviter, role, expiry, and acceptance link" do
    invitation = Invitation.create!(
      organization: organizations(:garden_club),
      invited_by: users(:owner),
      email: "mailer.student@example.com",
      role: :coordinator
    )

    mail = InvitationMailer.with(invitation: invitation, token: invitation.token).invite

    assert_equal [ invitation.email ], mail.to
    assert_equal "You’ve been invited to join Community Garden Club on Tabled", mail.subject
    assert_match users(:owner).name, mail.body.encoded
    assert_match "coordinator", mail.body.encoded
    assert_match invitation.expires_at.to_date.to_fs(:long), mail.body.encoded
    acceptance_url = Rails.application.routes.url_helpers.invitation_acceptance_url(invitation.token, host: "example.com")
    assert_includes mail.text_part.body.decoded, acceptance_url
    assert_includes mail.text_part.body.encoded, acceptance_url
  end
end
