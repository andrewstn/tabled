class OrganizationJoinLink < ApplicationRecord
  PUBLIC_ROLES = %w[member].freeze

  belongs_to :organization
  belongs_to :created_by, class_name: "User", inverse_of: :created_join_links

  enum :role, Membership::ROLES.index_by(&:itself), validate: true

  validates :label, presence: true, length: { maximum: 120 }
  validates :role, inclusion: { in: PUBLIC_ROLES }
  validates :max_uses, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :uses_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :available, -> {
    joins(:organization)
      .merge(Organization.active)
      .where(active: true)
      .where(expires_at: [ nil, Time.current.. ])
      .where("max_uses IS NULL OR uses_count < max_uses")
  }

  def token
    signed_id(purpose: :organization_join)
  end

  def self.find_by_token(token)
    find_signed(token.to_s, purpose: :organization_join)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def available?
    !organization.archived? && active? && !expired? && !full?
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def full?
    max_uses.present? && uses_count >= max_uses
  end

  def status
    return "Disabled" unless active?
    return "Expired" if expired?
    return "Limit reached" if full?

    "Active"
  end
end
