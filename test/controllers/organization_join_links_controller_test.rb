require "test_helper"

class OrganizationJoinLinksControllerTest < ActionDispatch::IntegrationTest
  test "owner can create and view a recruitment link" do
    sign_in_as(users(:owner))

    assert_difference([ "OrganizationJoinLink.count", "ActivityLogEntry.count" ]) do
      post organization_join_links_path(organizations(:film_society)), params: {
        organization_join_link: { label: "Autumn Fair", max_uses: 50 }
      }
    end

    link = OrganizationJoinLink.order(:created_at).last
    assert_equal "member", link.role
    assert_equal users(:owner), link.created_by
    assert_equal "recruitment_link.created", ActivityLogEntry.order(:created_at).last.action
    assert_not ActivityLogEntry.order(:created_at).last.metadata.key?("token")
    assert_redirected_to organization_join_links_path(organizations(:film_society))

    get organization_join_links_path(organizations(:film_society))
    assert_response :success
    assert_select "h2", "Autumn Fair"
    assert_includes response.body, "/join/#{link.token}"
  end

  test "officer can create a recruitment link" do
    memberships(:film_member).update!(role: :officer)
    sign_in_as(users(:member))

    assert_difference("OrganizationJoinLink.count") do
      post organization_join_links_path(organizations(:film_society)), params: {
        organization_join_link: { label: "Group chat" }
      }
    end
  end

  test "member cannot manage recruitment links" do
    sign_in_as(users(:member))

    get organization_join_links_path(organizations(:film_society))
    assert_response :forbidden

    assert_no_difference("OrganizationJoinLink.count") do
      post organization_join_links_path(organizations(:film_society)), params: {
        organization_join_link: { label: "Not allowed" }
      }
    end
    assert_response :forbidden
  end

  test "non-member cannot manage recruitment links" do
    sign_in_as(users(:member))

    get organization_join_links_path(organizations(:garden_club))

    assert_response :not_found
  end

  test "organizer can disable only an organization-scoped link" do
    link = create_join_link
    other = create_join_link(organization: organizations(:garden_club))
    sign_in_as(users(:owner))

    assert_difference("ActivityLogEntry.count") do
      delete organization_join_link_path(organizations(:film_society), link)
    end
    assert_not link.reload.active?
    assert_equal "recruitment_link.disabled", ActivityLogEntry.order(:created_at).last.action

    delete organization_join_link_path(organizations(:film_society), other)
    assert_response :not_found
    assert other.reload.active?
  end

  private

  def create_join_link(organization: organizations(:film_society))
    OrganizationJoinLink.create!(organization: organization, created_by: users(:owner), label: "Fair table", role: :member)
  end

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
