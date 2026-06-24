class User < ApplicationRecord
  has_many :created_join_links, class_name: "OrganizationJoinLink", foreign_key: :created_by_id, inverse_of: :created_by, dependent: :restrict_with_error
  has_secure_password

  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id,
    inverse_of: :invited_by, dependent: :restrict_with_error
  has_many :created_events, class_name: "Event", foreign_key: :created_by_id,
    inverse_of: :created_by, dependent: :restrict_with_error
  has_many :marked_attendance_records, class_name: "AttendanceRecord", foreign_key: :marked_by_id,
    inverse_of: :marked_by, dependent: :nullify
  has_many :authored_announcements, class_name: "Announcement", foreign_key: :author_id,
    inverse_of: :author, dependent: :restrict_with_error
  has_many :activity_log_entries, class_name: "ActivityLogEntry", foreign_key: :actor_id,
    inverse_of: :actor, dependent: :nullify

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :name, presence: true, length: { maximum: 100 }
  validates :email_address, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
end
