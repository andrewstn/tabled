require "test_helper"

class OrganizationJoinAcceptancesControllerTest < ActionDispatch::IntegrationTest
  test "public valid recruitment link loads and remembers the destination" do
    link = create_join_link

    get organization_join_path(link.token)

    assert_response :success
    assert_select "h1", "Join #{organizations(:film_society).name}"
    assert_select "a", "Create an account"
    assert_equal organization_join_path(link.token), session[:return_to_after_authenticating]
  end

  test "disabled expired and full links explain why they are unavailable" do
    disabled = create_join_link(active: false)
    expired = create_join_link(expires_at: 1.minute.ago)
    full = create_join_link(max_uses: 1, uses_count: 1)

    get organization_join_path(disabled.token)
    assert_select "h2", "This recruitment link is no longer active."

    get organization_join_path(expired.token)
    assert_select "h2", "This recruitment link has expired."

    get organization_join_path(full.token)
    assert_select "h2", "This recruitment link has reached its limit."
  end

  test "existing member sees an already joined state" do
    link = create_join_link
    sign_in_as(users(:member))

    get organization_join_path(link.token)

    assert_response :success
    assert_select "h2", "You’re already a member."
  end

  test "invalid token returns a safe not found state" do
    get organization_join_path("not-a-token")

    assert_response :not_found
    assert_select "h1", "Recruitment link unavailable"
  end

  test "authenticated non-member joins only the link organization" do
    link = create_join_link
    user = create_non_member
    sign_in_as(user)

    assert_difference([ "Membership.count", "link.reload.uses_count" ], 1) do
      patch organization_join_path(link.token)
    end

    membership = user.memberships.find_by!(organization: organizations(:film_society))
    assert_equal "member", membership.role
    assert_redirected_to organization_path(organizations(:film_society))
    assert_not user.memberships.exists?(organization: organizations(:garden_club))
  end

  test "existing member does not create a membership or use the link" do
    link = create_join_link
    sign_in_as(users(:member))

    assert_no_difference([ "Membership.count", "link.reload.uses_count" ]) do
      patch organization_join_path(link.token)
    end

    assert_redirected_to organization_path(organizations(:film_society))
  end

  test "disabled expired and full links cannot be accepted" do
    sign_in_as(create_non_member)

    [
      create_join_link(active: false),
      create_join_link(expires_at: 1.minute.ago),
      create_join_link(max_uses: 1, uses_count: 1)
    ].each do |link|
      assert_no_difference([ "Membership.count", "link.reload.uses_count" ]) do
        patch organization_join_path(link.token)
      end
      assert_response :unprocessable_entity
    end
  end

  test "joining requires authentication" do
    link = create_join_link

    assert_no_difference("Membership.count") do
      patch organization_join_path(link.token)
    end

    assert_redirected_to new_session_path
  end

  test "account creation returns to the recruitment link" do
    link = create_join_link
    get organization_join_path(link.token)

    post users_path, params: {
      user: { name: "New Student", email_address: "new.student@example.com", password: "password1234", password_confirmation: "password1234" }
    }

    assert_redirected_to organization_join_path(link.token)
  end

  private

  def create_join_link(**attributes)
    OrganizationJoinLink.create!({
      organization: organizations(:film_society), created_by: users(:owner), label: "Autumn Fair", role: :member
    }.merge(attributes))
  end

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end

  def create_non_member
    User.create!(name: "Taylor Student", email_address: "taylor.student@example.com", password: "password1234")
  end
end
