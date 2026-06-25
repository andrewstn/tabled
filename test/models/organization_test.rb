require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "name has a generous maximum length" do
    organization = organizations(:film_society)
    organization.name = "A" * (Organization::NAME_MAX_LENGTH + 1)

    assert_not organization.valid?
    assert_includes organization.errors[:name], "is too long (maximum is #{Organization::NAME_MAX_LENGTH} characters)"
  end

  test "description has a generous maximum length" do
    organization = organizations(:film_society)
    organization.description = "A" * (Organization::DESCRIPTION_MAX_LENGTH + 1)

    assert_not organization.valid?
    assert_includes organization.errors[:description], "is too long (maximum is #{Organization::DESCRIPTION_MAX_LENGTH} characters)"
  end

  test "settings fields accept practical organization details" do
    organization = organizations(:film_society)

    assert organization.update(
      contact_email: "film@example.test",
      website_url: "https://film.example.test",
      meeting_note: "Student Union screening room on Fridays",
      current_semester_label: "Fall 2026"
    )
  end

  test "contact email must be valid when present" do
    organization = organizations(:film_society)

    organization.contact_email = "not-email"

    assert_not organization.valid?
    assert_includes organization.errors[:contact_email], "is invalid"
  end

  test "website must use http or https when present" do
    organization = organizations(:film_society)

    organization.website_url = "ftp://example.test"

    assert_not organization.valid?
    assert_includes organization.errors[:website_url], "must start with http:// or https://"
  end
end
