class SemesterReport
  MemberParticipation = Data.define(
    :membership,
    :rsvp_attending_count,
    :present_count,
    :late_count,
    :excused_count,
    :absent_count,
    :last_attended_record,
    :recorded_event_count
  ) do
    def user
      membership.user
    end

    def attended_count
      present_count
    end

    def attendance_rate
      return nil if recorded_event_count.zero?

      (((present_count + late_count).to_f / recorded_event_count) * 100).round
    end

    def attendance_rate_label
      return "Not enough attendance recorded" unless attendance_rate

      "#{attendance_rate}%"
    end
  end

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

  def member_participation
    @member_participation ||= begin
      memberships = organization.memberships.includes(:user).order("users.name", "memberships.id").references(:user)
      rsvp_counts = organization.rsvps.attending.group(:membership_id).count
      attendance_counts = organization.attendance_records
        .where(event_id: recorded_attendance_event_ids)
        .group(:membership_id, :status)
        .count
      last_attendance_by_membership_id = last_attendance_records.index_by(&:membership_id)

      memberships.map do |membership|
        MemberParticipation.new(
          membership: membership,
          rsvp_attending_count: rsvp_counts.fetch(membership.id, 0),
          present_count: attendance_counts.fetch([ membership.id, "present" ], 0),
          late_count: attendance_counts.fetch([ membership.id, "late" ], 0),
          excused_count: attendance_counts.fetch([ membership.id, "excused" ], 0),
          absent_count: attendance_counts.fetch([ membership.id, "absent" ], 0),
          last_attended_record: last_attendance_by_membership_id[membership.id],
          recorded_event_count: recorded_attendance_event_ids.size
        )
      end
    end
  end

  def empty?
    total_members.zero? && organization.events.none? && organization.announcements.none?
  end

  private

  def past_events
    organization.events.past
  end

  def recorded_attendance_event_ids
    @recorded_attendance_event_ids ||= recorded_attendance_events.pluck(:id)
  end

  def last_attendance_records
    return AttendanceRecord.none if recorded_attendance_event_ids.empty?

    organization.attendance_records
      .where(event_id: recorded_attendance_event_ids, status: %w[present late])
      .joins(:event)
      .includes(:event)
      .order("events.starts_at DESC", "attendance_records.id DESC")
      .each_with_object([]) do |record, records|
        records << record unless records.any? { |existing| existing.membership_id == record.membership_id }
      end
  end
end
