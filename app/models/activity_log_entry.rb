class ActivityLogEntry < ApplicationRecord
  belongs_to :organization
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true, optional: true

  before_validation :set_occurred_at

  validates :action, presence: true
  validates :summary, presence: true
  validates :occurred_at, presence: true

  scope :recent_first, -> { order(occurred_at: :desc, id: :desc) }

  private

  def set_occurred_at
    self.occurred_at ||= Time.current
  end
end
