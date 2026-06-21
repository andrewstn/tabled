class Invitation < ApplicationRecord
  DEFAULT_EXPIRATION = 7.days

  belongs_to :organization
  belongs_to :invited_by, class_name: "User", inverse_of: :sent_invitations

  enum :role, Membership::ROLES.index_by(&:itself), validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  scope :unresolved, -> { where(accepted_at: nil, revoked_at: nil) }
  scope :pending, -> { unresolved.where(expires_at: Time.current..) }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: {
      scope: :organization_id,
      case_sensitive: false,
      conditions: -> { unresolved },
      message: "already has a pending invitation"
    }
  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :email_is_not_a_current_member, on: :create

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  attr_reader :token

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.find_by_token(token)
    find_by(token_digest: digest(token)) if token.present?
  end

  def pending?
    accepted_at.nil? && revoked_at.nil? && !expired?
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def revoked?
    revoked_at.present?
  end

  def status
    return "Accepted" if accepted?
    return "Revoked" if revoked?
    return "Expired" if expired?

    "Pending"
  end

  private

  def generate_token
    @token = SecureRandom.urlsafe_base64(32)
    self.token_digest = self.class.digest(@token)
  end

  def set_expiration
    self.expires_at ||= DEFAULT_EXPIRATION.from_now
  end

  def email_is_not_a_current_member
    return if organization.blank? || email.blank?

    if organization.users.where("lower(email_address) = ?", email.downcase).exists?
      errors.add(:email, "is already on the member roster")
    end
  end
end
