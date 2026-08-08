class AnnouncementDelivery < ApplicationRecord
  STATUSES = %w[sent skipped].freeze
  SKIPPED_REASONS = %w[announcement_emails_disabled missing_email].freeze

  belongs_to :announcement
  belongs_to :membership
  belongs_to :user, optional: true

  enum :status, STATUSES.index_by(&:itself), validate: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :membership_id, uniqueness: { scope: :announcement_id }
  validates :skipped_reason, inclusion: { in: SKIPPED_REASONS }, allow_nil: true
  validate :sent_deliveries_have_sent_at
  validate :skipped_deliveries_have_reason

  private

  def sent_deliveries_have_sent_at
    return unless sent?
    return if sent_at.present?

    errors.add(:sent_at, "must be set for sent deliveries")
  end

  def skipped_deliveries_have_reason
    return unless skipped?
    return if skipped_reason.present?

    errors.add(:skipped_reason, "must be set for skipped deliveries")
  end
end
