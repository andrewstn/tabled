require "test_helper"

class CommunicationPreferencesControllerTest < ActionDispatch::IntegrationTest
  test "member can view their own communication preferences" do
    sign_in_as(users(:member))

    get organization_communication_preferences_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Communication preferences"
    assert_select "p", text: /These settings only apply to Buckeye Film Society/
  end

  test "member can update their own communication preferences" do
    membership = memberships(:film_member)
    sign_in_as(users(:member))

    assert_difference("ActivityLogEntry.count") do
      patch organization_communication_preferences_path(organizations(:film_society)), params: {
        membership: {
          announcement_emails_enabled: "0",
          event_reminder_emails_enabled: "0",
          recruitment_emails_enabled: "0"
        }
      }
    end

    assert_redirected_to organization_communication_preferences_path(organizations(:film_society))
    membership.reload
    assert_not_predicate membership, :announcement_emails_enabled?
    assert_not_predicate membership, :event_reminder_emails_enabled?
    assert_not_predicate membership, :recruitment_emails_enabled?
    entry = ActivityLogEntry.order(:created_at).last
    assert_equal "communication_preferences.updated", entry.action
    assert_not entry.metadata.key?("announcement_emails_enabled")
  end

  test "member cannot update another member preferences through submitted ids" do
    owner_membership = memberships(:film_owner)
    sign_in_as(users(:member))

    patch organization_communication_preferences_path(organizations(:film_society)), params: {
      membership_id: owner_membership.id,
      membership: {
        announcement_emails_enabled: "0",
        event_reminder_emails_enabled: "1",
        recruitment_emails_enabled: "1"
      }
    }

    assert_predicate owner_membership.reload, :announcement_emails_enabled?
    assert_not_predicate memberships(:film_member).reload, :announcement_emails_enabled?
  end

  test "non-member cannot access communication preferences" do
    sign_in_as(users(:member))

    get organization_communication_preferences_path(organizations(:garden_club))

    assert_response :not_found
  end

  test "preferences are scoped by organization" do
    garden_membership = Membership.create!(organization: organizations(:garden_club), user: users(:member), role: :member)
    sign_in_as(users(:member))

    patch organization_communication_preferences_path(organizations(:film_society)), params: {
      membership: {
        announcement_emails_enabled: "0",
        event_reminder_emails_enabled: "1",
        recruitment_emails_enabled: "1"
      }
    }

    assert_not_predicate memberships(:film_member).reload, :announcement_emails_enabled?
    assert_predicate garden_membership.reload, :announcement_emails_enabled?
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
