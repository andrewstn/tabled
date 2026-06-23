class Announcement < ApplicationRecord
  AUDIENCES = %w[all_members officers event_rsvps event_attendees].freeze
  EVENT_AUDIENCES = %w[event_rsvps event_attendees].freeze
  STATUSES = %w[draft published].freeze

  belongs_to :organization
  belongs_to :author, class_name: "User", inverse_of: :authored_announcements
  belongs_to :target_event, class_name: "Event", optional: true

  enum :audience, AUDIENCES.index_by(&:itself), validate: true
  enum :status, STATUSES.index_by(&:itself), validate: true

  validates :title, presence: true, length: { maximum: 160 }
  validates :body, presence: true, length: { maximum: 10_000 }
  validate :target_event_required_for_event_audience
  validate :target_event_belongs_to_organization

  before_validation :set_published_at, if: :published?
  before_validation :clear_published_at, if: :draft?

  scope :bulletin_order, -> { order(pinned: :desc, published_at: :desc, created_at: :desc) }
  scope :published_for, ->(membership) {
    relation = published.where(audience: "all_members")
    relation = relation.or(published.where(audience: "officers")) if membership.owner? || membership.officer? || membership.coordinator?
    relation = relation.or(published.where(audience: "event_rsvps", target_event_id: membership.rsvps.select(:event_id)))
    relation.or(published.where(audience: "event_attendees", target_event_id: membership.attendance_records.where(status: %w[present late]).select(:event_id)))
  }

  def audience_label
    case audience
    when "all_members" then "All members"
    when "officers" then "Officers"
    when "event_rsvps" then "Event RSVPs"
    when "event_attendees" then "Checked-in attendees"
    end
  end

  def recipient_memberships
    AnnouncementAudienceResolver.new(self).memberships
  end

  def event_audience?
    EVENT_AUDIENCES.include?(audience)
  end

  private

  def set_published_at
    self.published_at ||= Time.current
  end

  def clear_published_at
    self.published_at = nil
  end

  def target_event_required_for_event_audience
    return unless event_audience?
    return if target_event.present?

    errors.add(:target_event, "must be selected for this audience")
  end

  def target_event_belongs_to_organization
    return if target_event.blank? || organization.blank?
    return if target_event.organization_id == organization_id

    errors.add(:target_event, "must belong to this organization")
  end
end
