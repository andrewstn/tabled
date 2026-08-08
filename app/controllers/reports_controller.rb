require "csv"

class ReportsController < ApplicationController
  before_action :set_organization
  before_action :require_report_viewer

  def show
    @report = SemesterReport.new(organization: @organization)
    @member_participation_paginator = Paginator.new(@report.member_participation, page: params[:page], per_page: 10)
    @member_participation_rows = @member_participation_paginator.records
  end

  def roster
    record_export_activity("roster")
    send_data roster_csv,
      filename: "#{@organization.slug}-roster.csv",
      type: "text/csv; charset=utf-8"
  end

  def participation
    record_export_activity("participation")
    send_data participation_csv,
      filename: "#{@organization.slug}-participation.csv",
      type: "text/csv; charset=utf-8"
  end

  def events
    record_export_activity("event summary")
    send_data event_summary_csv,
      filename: "#{@organization.slug}-event-summary.csv",
      type: "text/csv; charset=utf-8"
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_slug])
  end

  def require_report_viewer
    raise ActiveRecord::RecordNotFound unless OrganizationPolicy.new(current_user, @organization).show?
    head :forbidden unless ReportPolicy.new(current_user, @organization).show?
  end

  def report
    @report ||= SemesterReport.new(organization: @organization)
  end

  def roster_csv
    CSV.generate(headers: true) do |csv|
      csv << [ "Name", "Email", "Role", "Joined at" ]
      @organization.memberships.includes(:user).order("users.name", "memberships.id").references(:user).each do |membership|
        csv << [
          safe_csv_cell(membership.user.name),
          safe_csv_cell(membership.user.email_address),
          membership.role,
          membership.created_at.iso8601
        ]
      end
    end
  end

  def participation_csv
    CSV.generate(headers: true) do |csv|
      csv << [
        "Name",
        "Email",
        "Role",
        "Joined at",
        "RSVP attending count",
        "Events attended count",
        "Late count",
        "Excused count",
        "Absent count",
        "Last attended at",
        "Attendance rate"
      ]
      report.member_participation.each do |row|
        csv << [
          safe_csv_cell(row.user.name),
          safe_csv_cell(row.user.email_address),
          row.membership.role,
          row.membership.created_at.iso8601,
          row.rsvp_attending_count,
          row.attended_count,
          row.late_count,
          row.excused_count,
          row.absent_count,
          row.last_attended_record&.event&.starts_at&.iso8601,
          row.attendance_rate
        ]
      end
    end
  end

  def event_summary_csv
    CSV.generate(headers: true) do |csv|
      csv << [
        "Event title",
        "Starts at",
        "Location",
        "RSVP attending count",
        "Present count",
        "Late count",
        "Excused count",
        "Absent count",
        "Attendance recorded"
      ]
      report.event_summaries.each do |row|
        csv << [
          safe_csv_cell(row.event.title),
          row.event.starts_at.iso8601,
          safe_csv_cell(row.event.location),
          row.rsvp_attending_count,
          row.present_count,
          row.late_count,
          row.excused_count,
          row.absent_count,
          row.attendance_recorded? ? "Yes" : "No"
        ]
      end
    end
  end

  def safe_csv_cell(value)
    value.to_s.match?(/\A[=+\-@]/) ? "'#{value}" : value
  end

  def record_export_activity(report_name)
    ActivityLog.record(
      organization: @organization,
      actor: current_user,
      action: "report.exported",
      summary: "#{current_user.name} exported the #{report_name} report.",
      metadata: { report: report_name, format: "csv" }
    )
  end
end
