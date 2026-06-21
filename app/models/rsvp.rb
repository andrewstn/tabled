class Rsvp < ApplicationRecord
  STATUSES = %w[attending maybe not_attending].freeze

  belongs_to :event
  belongs_to :membership

  enum :status, STATUSES.index_by(&:itself), validate: true

  validates :membership_id, uniqueness: { scope: :event_id }
  validates :note, length: { maximum: 1_000 }
  validate :membership_belongs_to_event_organization

  private

  def membership_belongs_to_event_organization
    return if event.blank? || membership.blank?
    return if event.organization_id == membership.organization_id

    errors.add(:membership, "must belong to the event organization")
  end
end
