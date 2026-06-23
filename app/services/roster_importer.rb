require "csv"

class RosterImporter
  Result = Data.define(:rows) do
    def created_count
      rows.count(&:created?)
    end

    def skipped_count
      rows.count(&:skipped?)
    end

    def invalid_count
      rows.count(&:invalid?)
    end
  end

  RowResult = Data.define(:number, :name, :email, :role, :status, :message, :invitation) do
    def created?
      status == :created
    end

    def skipped?
      status == :skipped
    end

    def invalid?
      status == :invalid
    end
  end

  def initialize(organization:, invited_by:, csv_content:)
    @organization = organization
    @invited_by = invited_by
    @csv_content = csv_content
    @permitted_roles = InvitationPolicy.new(invited_by, organization).permitted_roles - [ "owner" ]
  end

  def import
    Result.new(rows: parsed_rows.map { |number, row| import_row(number, row) })
  rescue CSV::MalformedCSVError => error
    Result.new(rows: [
      RowResult.new(number: 1, name: nil, email: nil, role: nil, status: :invalid, message: "CSV could not be read: #{error.message}", invitation: nil)
    ])
  end

  private

  attr_reader :organization, :invited_by, :csv_content, :permitted_roles

  def parsed_rows
    CSV.parse(csv_content.to_s, headers: true).each_with_index.map { |row, index| [ index + 2, row ] }
  end

  def import_row(number, row)
    name = cell(row, "name")
    email = normalize_email(cell(row, "email"))
    role = normalize_role(cell(row, "role"))

    return invalid_row(number, name, email, role, "Email is required") if email.blank?
    return invalid_row(number, name, email, role, "Email is invalid") unless valid_email?(email)
    return invalid_row(number, name, email, role, "Role is invalid") unless Membership::ROLES.include?(role)
    return invalid_row(number, name, email, role, "Owner invitations cannot be imported") if role == "owner"
    return invalid_row(number, name, email, role, "Role is not permitted for your account") unless permitted_roles.include?(role)
    return skipped_row(number, name, email, role, "Already on the roster") if existing_member?(email)
    return skipped_row(number, name, email, role, "Pending invitation already exists") if pending_invitation?(email)

    invitation = organization.invitations.create(organization: organization, invited_by: invited_by, email: email, role: role)
    if invitation.persisted?
      RowResult.new(number: number, name: name, email: email, role: role, status: :created, message: "Invitation created", invitation: invitation)
    else
      invalid_row(number, name, email, role, invitation.errors.full_messages.to_sentence)
    end
  end

  def cell(row, header)
    row[header]&.to_s&.strip
  end

  def normalize_email(value)
    value.to_s.strip.downcase
  end

  def normalize_role(value)
    value.to_s.strip.presence || "member"
  end

  def valid_email?(email)
    email.match?(URI::MailTo::EMAIL_REGEXP)
  end

  def existing_member?(email)
    organization.memberships.joins(:user).where("LOWER(users.email_address) = ?", email.downcase).exists?
  end

  def pending_invitation?(email)
    organization.invitations.pending.where("LOWER(email) = ?", email.downcase).exists?
  end

  def invalid_row(number, name, email, role, message)
    RowResult.new(number: number, name: name, email: email, role: role, status: :invalid, message: message, invitation: nil)
  end

  def skipped_row(number, name, email, role, message)
    RowResult.new(number: number, name: name, email: email, role: role, status: :skipped, message: message, invitation: nil)
  end
end
