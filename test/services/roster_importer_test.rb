require "test_helper"

class RosterImporterTest < ActiveSupport::TestCase
  test "creates invitations for valid rows and normalizes email case" do
    result = import_csv(<<~CSV)
      name,email,role
      New Member,NEW.STUDENT@EXAMPLE.TEST,member
    CSV

    assert_equal 1, result.created_count
    invitation = organizations(:film_society).invitations.find_by!(email: "new.student@example.test")
    assert_equal "member", invitation.role
    assert_equal users(:owner), invitation.invited_by
  end

  test "defaults missing role to member" do
    result = import_csv(<<~CSV)
      name,email,role
      Default Member,default-member@example.test,
    CSV

    assert_equal 1, result.created_count
    assert_equal "member", organizations(:film_society).invitations.find_by!(email: "default-member@example.test").role
  end

  test "skips existing members" do
    result = import_csv(<<~CSV)
      name,email,role
      Existing Member,#{users(:member).email_address},member
    CSV

    assert_equal 0, result.created_count
    assert_equal 1, result.skipped_count
    assert_equal "Already on the roster", result.rows.first.message
  end

  test "skips duplicate pending invitations" do
    result = import_csv(<<~CSV)
      name,email,role
      Pending Member,#{invitations(:pending_member).email.upcase},member
    CSV

    assert_equal 0, result.created_count
    assert_equal 1, result.skipped_count
    assert_equal "Pending invitation already exists", result.rows.first.message
  end

  test "rejects missing and invalid emails" do
    result = import_csv(<<~CSV)
      name,email,role
      Missing Email,,member
      Invalid Email,not-an-email,member
    CSV

    assert_equal 2, result.invalid_count
    assert_equal [ "Email is required", "Email is invalid" ], result.rows.map(&:message)
  end

  test "rejects invalid roles" do
    result = import_csv(<<~CSV)
      name,email,role
      Bad Role,bad-role@example.test,president
    CSV

    assert_equal 1, result.invalid_count
    assert_equal "Role is invalid", result.rows.first.message
  end

  test "does not create owner invitations from CSV" do
    result = import_csv(<<~CSV)
      name,email,role
      Owner Import,owner-import@example.test,owner
    CSV

    assert_equal 1, result.invalid_count
    assert_equal "Owner invitations cannot be imported", result.rows.first.message
    assert_nil organizations(:film_society).invitations.find_by(email: "owner-import@example.test")
  end

  test "officer imports only roles permitted by invitation policy" do
    memberships(:film_member).update!(role: :officer)
    result = import_csv(<<~CSV, invited_by: users(:member))
      name,email,role
      New Officer,new-officer@example.test,officer
      New Coordinator,new-coordinator@example.test,coordinator
    CSV

    assert_equal 1, result.created_count
    assert_equal 1, result.invalid_count
    assert_equal "Role is not permitted for your account", result.rows.first.message
    assert_equal "coordinator", organizations(:film_society).invitations.find_by!(email: "new-coordinator@example.test").role
  end

  test "import is organization scoped" do
    Membership.create!(organization: organizations(:garden_club), user: users(:owner), role: :officer)
    result = import_csv(<<~CSV, organization: organizations(:garden_club))
      name,email,role
      Film Member,#{users(:member).email_address},member
    CSV

    assert_equal 1, result.created_count
    assert_equal organizations(:garden_club), result.rows.first.invitation.organization
  end

  private

  def import_csv(csv, organization: organizations(:film_society), invited_by: users(:owner))
    RosterImporter.new(organization: organization, invited_by: invited_by, csv_content: csv).import
  end
end
