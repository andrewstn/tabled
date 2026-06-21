require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "requires a unique well-formed slug" do
    organization = Organization.new(name: "Another club", slug: organizations(:film_society).slug)

    assert_not organization.valid?
    assert_includes organization.errors[:slug], "has already been taken"

    organization.slug = "Not A Slug"
    assert_not organization.valid?
  end

  test "connects users through memberships" do
    assert_includes organizations(:film_society).users, users(:owner)
    assert_includes users(:owner).organizations, organizations(:film_society)
  end
end
