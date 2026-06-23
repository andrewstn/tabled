class Organization < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :invitations, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :rsvps, through: :events
  has_many :attendance_records, through: :events
  has_many :announcements, dependent: :destroy
  has_many :organization_join_links, dependent: :destroy

  validates :name, presence: true, length: { maximum: 120 }
  validates :slug, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "may only contain lowercase letters, numbers, and hyphens" }
  validates :description, length: { maximum: 1_000 }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must start with http:// or https://" }, allow_blank: true
  validates :meeting_note, length: { maximum: 255 }
  validates :current_semester_label, length: { maximum: 80 }

  def to_param
    slug
  end
end
