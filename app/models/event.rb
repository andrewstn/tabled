class Event < ApplicationRecord
  belongs_to :organization
  belongs_to :created_by, class_name: "User", inverse_of: :created_events
  has_many :rsvps, dependent: :destroy

  validates :title, presence: true, length: { maximum: 160 }
  validates :description, length: { maximum: 5_000 }
  validates :location, length: { maximum: 255 }
  validates :starts_at, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :ends_after_start
  validate :rsvp_deadline_not_after_start

  scope :upcoming, -> { where(starts_at: Time.current..).order(:starts_at) }
  scope :past, -> { where(starts_at: ...Time.current).order(starts_at: :desc) }

  def upcoming?
    starts_at.present? && starts_at >= Time.current
  end

  def past?
    starts_at.present? && starts_at < Time.current
  end

  def attending_count
    rsvps.attending.count
  end

  def full?
    capacity.present? && attending_count >= capacity
  end

  def rsvp_deadline_passed?
    rsvp_deadline.present? && rsvp_deadline < Time.current
  end

  private

  def ends_after_start
    return if ends_at.blank? || starts_at.blank? || ends_at > starts_at

    errors.add(:ends_at, "must be after the start time")
  end

  def rsvp_deadline_not_after_start
    return if rsvp_deadline.blank? || starts_at.blank? || rsvp_deadline <= starts_at

    errors.add(:rsvp_deadline, "must be on or before the start time")
  end
end
