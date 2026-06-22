class Event < ApplicationRecord
  has_secure_password :check_in_code, validations: false

  belongs_to :organization
  belongs_to :created_by, class_name: "User", inverse_of: :created_events
  has_many :rsvps, dependent: :destroy
  has_many :attendance_records, dependent: :destroy

  validates :title, presence: true, length: { maximum: 160 }
  validates :description, length: { maximum: 5_000 }
  validates :location, length: { maximum: 255 }
  validates :starts_at, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :ends_after_start
  validate :rsvp_deadline_not_after_start
  validate :check_in_closes_after_opening

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

  def check_in_state
    return :not_opened if check_in_opens_at.blank? || check_in_code_digest.blank?
    return :not_opened if check_in_opens_at > Time.current
    return :closed if check_in_closes_at.present? && check_in_closes_at <= Time.current

    :open
  end

  def check_in_open?
    check_in_state == :open
  end

  def regenerate_check_in_code
    code = SecureRandom.alphanumeric(6).upcase
    self.check_in_code = code
    code
  end

  def valid_check_in_code?(code)
    check_in_code_digest.present? && authenticate_check_in_code(code.to_s.strip.upcase).present?
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


  def check_in_closes_after_opening
    return if check_in_opens_at.blank? || check_in_closes_at.blank? || check_in_closes_at > check_in_opens_at

    errors.add(:check_in_closes_at, "must be after check-in opens")
  end
end
