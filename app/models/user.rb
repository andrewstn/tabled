class User < ApplicationRecord
  has_secure_password

  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id,
    inverse_of: :invited_by, dependent: :restrict_with_error
  has_many :created_events, class_name: "Event", foreign_key: :created_by_id,
    inverse_of: :created_by, dependent: :restrict_with_error
  has_many :marked_attendance_records, class_name: "AttendanceRecord", foreign_key: :marked_by_id,
    inverse_of: :marked_by, dependent: :nullify

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :name, presence: true, length: { maximum: 100 }
  validates :email_address, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
end
