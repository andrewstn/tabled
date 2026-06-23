class SemesterReport
  attr_reader :organization

  def initialize(organization:)
    @organization = organization
  end

  def total_members
    organization.memberships.count
  end

  def events_held
    past_events.count
  end

  def events_with_attendance_recorded
    past_events.joins(:attendance_records).distinct.count
  end

  def upcoming_events
    organization.events.upcoming.count
  end

  def published_announcements
    organization.announcements.published.count
  end

  def pending_invitations
    organization.invitations.pending.count
  end

  def active_recruitment_links
    organization.organization_join_links.available.count
  end

  def recorded_attendance_events
    @recorded_attendance_events ||= past_events.joins(:attendance_records).reorder(nil).distinct
  end

  def attendance_status_counts
    @attendance_status_counts ||= organization.attendance_records
      .where(event: recorded_attendance_events)
      .group(:status)
      .count
  end

  def attendance_count(status)
    attendance_status_counts.fetch(status.to_s, 0)
  end

  def empty?
    total_members.zero? && organization.events.none? && organization.announcements.none?
  end

  private

  def past_events
    organization.events.past
  end
end
