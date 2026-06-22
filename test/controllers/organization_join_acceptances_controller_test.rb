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
    assert_select "h2", "You’re already around the table."
  end

  test "invalid token returns a safe not found state" do
    get organization_join_path("not-a-token")

    assert_response :not_found
    assert_select "h1", "Recruitment link unavailable"
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
end
