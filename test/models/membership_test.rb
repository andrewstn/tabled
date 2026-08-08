require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "communication preferences default to enabled" do
    membership = Membership.create!(
      organization: organizations(:garden_club),
      user: users(:member),
      role: :member
    )

    assert_predicate membership, :announcement_emails_enabled?
    assert_predicate membership, :event_reminder_emails_enabled?
    assert_predicate membership, :recruitment_emails_enabled?
  end

  test "communication preferences can be disabled per membership" do
    membership = memberships(:film_member)

    membership.update!(
      announcement_emails_enabled: false,
      event_reminder_emails_enabled: false,
      recruitment_emails_enabled: false
    )

    assert_not_predicate membership, :announcement_emails_enabled?
    assert_not_predicate membership, :event_reminder_emails_enabled?
    assert_not_predicate membership, :recruitment_emails_enabled?
  end
end
