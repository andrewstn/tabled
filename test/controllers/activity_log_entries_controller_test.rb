require "test_helper"

class ActivityLogEntriesControllerTest < ActionDispatch::IntegrationTest
  test "owner can view organization log book" do
    entry = create_entry(summary: "Alex updated organization settings.")
    sign_in_as(users(:owner))

    get organization_log_book_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Log book"
    assert_select "p", text: entry.summary
    assert_select "p", text: /Updated by #{Regexp.escape(users(:owner).name)}/
  end

  test "officer can view organization log book" do
    memberships(:film_member).update!(role: :officer)
    create_entry(summary: "Alex created Camera Workshop.")
    sign_in_as(users(:member))

    get organization_log_book_path(organizations(:film_society))

    assert_response :success
  end

  test "coordinator can view organization log book" do
    memberships(:film_member).update!(role: :coordinator)
    create_entry(summary: "Alex marked attendance.")
    sign_in_as(users(:member))

    get organization_log_book_path(organizations(:film_society))

    assert_response :success
  end

  test "member cannot view full log book" do
    sign_in_as(users(:member))

    get organization_log_book_path(organizations(:film_society))

    assert_response :forbidden
  end

  test "non-member cannot view log book" do
    sign_in_as(users(:member))

    get organization_log_book_path(organizations(:garden_club))

    assert_response :not_found
  end

  test "log book is scoped to the current organization" do
    create_entry(summary: "Film activity.")
    create_entry(organization: organizations(:garden_club), summary: "Garden activity.")
    Membership.create!(organization: organizations(:garden_club), user: users(:owner), role: :owner)
    sign_in_as(users(:owner))

    get organization_log_book_path(organizations(:film_society))

    assert_select "p", text: "Film activity."
    assert_select "p", text: "Garden activity.", count: 0
  end

  test "log book can filter by action" do
    create_entry(action: "event.created", summary: "Alex created Camera Workshop.")
    create_entry(action: "member.invited", summary: "Alex invited jordan@example.com.")
    sign_in_as(users(:owner))

    get organization_log_book_path(organizations(:film_society)), params: { action_filter: "event.created" }

    assert_select "p", text: "Alex created Camera Workshop."
    assert_select "p", text: "Alex invited jordan@example.com.", count: 0
    assert_select "a", text: "Clear"
  end

  test "log book paginates entries" do
    30.times do |index|
      create_entry(summary: "Recorded activity #{index}", occurred_at: index.minutes.ago)
    end
    sign_in_as(users(:owner))

    get organization_log_book_path(organizations(:film_society))

    assert_select "li", count: 25
    assert_select "nav[aria-label='Pagination']", text: /Showing 1–25 of 30/
  end

  test "empty log book shows warm empty state" do
    sign_in_as(users(:owner))

    get organization_log_book_path(organizations(:film_society))

    assert_select "p", text: "No notes in the log book yet."
  end

  private

  def create_entry(organization: organizations(:film_society), action: "settings.updated", summary:, occurred_at: Time.current)
    ActivityLogEntry.create!(
      organization: organization,
      actor: users(:owner),
      action: action,
      summary: summary,
      occurred_at: occurred_at
    )
  end

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
