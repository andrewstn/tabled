class Membership < ApplicationRecord
  ROLES = %w[owner officer coordinator member].freeze

  belongs_to :user
  belongs_to :organization

  enum :role, ROLES.index_by(&:itself), validate: true

  validates :user_id, uniqueness: { scope: :organization_id }
end
