require "test_helper"

class RosterImportsControllerTest < ActionDispatch::IntegrationTest
  test "owner can open roster import form" do
    sign_in_as(users(:owner))

    get new_organization_roster_import_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Import roster"
    assert_select "p", text: /Upload a CSV with name, email, and role/
  end

  test "member cannot open roster import form" do
    sign_in_as(users(:member))

    get new_organization_roster_import_path(organizations(:film_society))

    assert_response :forbidden
  end

  test "non-member cannot open roster import form" do
    sign_in_as(users(:member))

    get new_organization_roster_import_path(organizations(:garden_club))

    assert_response :not_found
  end

  test "import upload creates pending invitations and shows results" do
    sign_in_as(users(:owner))

    assert_difference("Invitation.count", 2) do
      post organization_roster_import_path(organizations(:film_society)), params: {
        roster_import: { csv_file: fixture_file_upload("roster_import.csv", "text/csv") }
      }
    end

    assert_response :success
    assert_select "h2", "Import results"
    assert_select "p", text: /2 invitations created/
    assert_equal "coordinator", organizations(:film_society).invitations.find_by!(email: "csv-coordinator@example.test").role
  end

  test "import upload shows skipped and invalid rows" do
    file = Tempfile.new([ "roster-import", ".csv" ])
    file.write <<~CSV
      name,email,role
      Existing,#{users(:member).email_address},member
      Broken,not-an-email,member
    CSV
    file.rewind
    sign_in_as(users(:owner))

    assert_no_difference("Membership.count") do
      post organization_roster_import_path(organizations(:film_society)), params: {
        roster_import: { csv_file: Rack::Test::UploadedFile.new(file.path, "text/csv") }
      }
    end

    assert_response :success
    assert_select "td", text: "Already on the roster"
    assert_select "td", text: "Email is invalid"
  ensure
    file&.close!
  end

  test "missing CSV file returns validation message" do
    sign_in_as(users(:owner))

    post organization_roster_import_path(organizations(:film_society)), params: { roster_import: {} }

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: "Choose a CSV file to import."
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
