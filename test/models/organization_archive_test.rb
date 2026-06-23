require "test_helper"

class OrganizationArchiveTest < ActiveSupport::TestCase
  test "archive and restore update archived state" do
    organization = organizations(:film_society)

    organization.archive!
    assert_predicate organization, :archived?

    organization.restore!
    assert_not_predicate organization, :archived?
  end
end
