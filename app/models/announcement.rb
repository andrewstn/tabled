class Announcement < ApplicationRecord
  AUDIENCES = %w[all_members officers].freeze
  STATUSES = %w[draft published].freeze

  belongs_to :organization
  belongs_to :author, class_name: "User", inverse_of: :authored_announcements

  enum :audience, AUDIENCES.index_by(&:itself), validate: true
  enum :status, STATUSES.index_by(&:itself), validate: true

  validates :title, presence: true, length: { maximum: 160 }
  validates :body, presence: true, length: { maximum: 10_000 }

  before_validation :set_published_at, if: :published?
  before_validation :clear_published_at, if: :draft?

  scope :bulletin_order, -> { order(pinned: :desc, published_at: :desc, created_at: :desc) }
  scope :published_for, ->(membership) {
    audiences = membership.member? ? [ "all_members" ] : AUDIENCES
    published.where(audience: audiences)
  }

  def audience_label
    audience == "all_members" ? "All members" : "Officers"
  end

  def recipient_memberships
    memberships = organization.memberships.includes(:user)
    officers? ? memberships.where(role: %w[owner officer coordinator]) : memberships
  end

  private

  def set_published_at
    self.published_at ||= Time.current
  end

  def clear_published_at
    self.published_at = nil
  end
end
