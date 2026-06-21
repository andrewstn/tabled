require "test_helper"

class OrganizationsCreationTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: users(:owner).email_address, password: "password1234" }
  end

  test "creates an organization with the current user as owner" do
    assert_difference([ "Organization.count", "Membership.count" ]) do
      post organizations_path, params: { organization: { name: "Campus Radio Club", description: "Student voices over the air." } }
    end

    organization = Organization.find_by!(slug: "campus-radio-club")
    assert_redirected_to organization_path(organization)
    assert_equal users(:owner), organization.memberships.owner.sole.user
  end

  test "generates a unique slug" do
    post organizations_path, params: { organization: { name: organizations(:film_society).name } }

    assert_equal "buckeye-film-society-2", Organization.order(:created_at).last.slug
  end

  test "does not create a membership when the organization is invalid" do
    assert_no_difference([ "Organization.count", "Membership.count" ]) do
      post organizations_path, params: { organization: { name: "" } }
    end

    assert_response :unprocessable_entity
  end
end
