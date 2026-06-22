class Membership < ApplicationRecord
  ROLES = %w[owner officer coordinator member].freeze

  belongs_to :user
  belongs_to :organization
  has_many :rsvps, dependent: :destroy
  has_many :attendance_records, dependent: :destroy

  enum :role, ROLES.index_by(&:itself), validate: true

  validates :user_id, uniqueness: { scope: :organization_id }
end
