require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "owner can view semester report" do
    sign_in_as(users(:owner))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Semester report"
    assert_select "p", text: "A practical record of members, gatherings, and attendance."
    assert_select "dt", text: "Current members"
    assert_select "dd", text: organizations(:film_society).memberships.count.to_s
  end

  test "officer can view semester report" do
    memberships(:film_member).update!(role: :officer)
    sign_in_as(users(:member))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Semester report"
  end

  test "coordinator can view semester report" do
    memberships(:film_member).update!(role: :coordinator)
    sign_in_as(users(:member))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Semester report"
  end

  test "member cannot view organization report" do
    sign_in_as(users(:member))

    get organization_reports_path(organizations(:film_society))

    assert_response :forbidden
  end

  test "non-member cannot view report" do
    sign_in_as(users(:member))

    get organization_reports_path(organizations(:garden_club))

    assert_response :not_found
  end

  test "report summary is scoped to current organization" do
    10.times do |index|
      Event.create!(
        organization: organizations(:garden_club),
        created_by: users(:owner),
        title: "Garden planning #{index}",
        starts_at: 1.day.ago
      )
    end
    Membership.create!(organization: organizations(:garden_club), user: users(:owner), role: :officer)
    sign_in_as(users(:owner))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "dd", text: organizations(:film_society).memberships.count.to_s
    assert_select "dd", text: "10", count: 0
  end

  test "report shows member participation table" do
    sign_in_as(users(:owner))

    get organization_reports_path(organizations(:film_society))

    assert_response :success
    assert_select "h2", "Participation record"
    assert_select "tbody th", text: /#{Regexp.escape(users(:owner).name)}/
    assert_select "span", text: users(:owner).email_address
    assert_select "td", text: "100%"
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
