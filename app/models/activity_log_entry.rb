class ActivityLogEntry < ApplicationRecord
  CATEGORY_LABELS = {
    "member" => "Members",
    "recruitment_link" => "Members",
    "roster" => "Members",
    "event" => "Gatherings",
    "rsvp" => "Gatherings",
    "check_in" => "Attendance",
    "attendance" => "Attendance",
    "announcement" => "Bulletin",
    "communication_preferences" => "Bulletin",
    "report" => "Reports",
    "settings" => "Settings",
    "ownership" => "Settings",
    "organization" => "Settings"
  }.freeze

  belongs_to :organization
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true, optional: true

  before_validation :set_occurred_at

  validates :action, presence: true
  validates :summary, presence: true
  validates :occurred_at, presence: true

  scope :recent_first, -> { order(occurred_at: :desc, id: :desc) }

  def category_label
    CATEGORY_LABELS.fetch(action.to_s.split(".").first, "Record")
  end

  def action_label
    action.to_s.tr("._", " ").squish.titleize
  end

  private

  def set_occurred_at
    self.occurred_at ||= Time.current
  end
end
