class Organization < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :invitations, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :attendance_records, through: :events
  has_many :announcements, dependent: :destroy
  has_many :organization_join_links, dependent: :destroy

  validates :name, presence: true, length: { maximum: 120 }
  validates :slug, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "may only contain lowercase letters, numbers, and hyphens" }
  validates :description, length: { maximum: 1_000 }

  def to_param
    slug
  end
end
