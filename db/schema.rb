# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_23_094000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "announcement_deliveries", force: :cascade do |t|
    t.bigint "announcement_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.bigint "membership_id", null: false
    t.datetime "sent_at"
    t.string "skipped_reason"
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["announcement_id", "membership_id"], name: "idx_on_announcement_id_membership_id_a7b4d846e6", unique: true
    t.index ["announcement_id"], name: "index_announcement_deliveries_on_announcement_id"
    t.index ["membership_id"], name: "index_announcement_deliveries_on_membership_id"
    t.index ["user_id"], name: "index_announcement_deliveries_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['sent'::character varying, 'skipped'::character varying]::text[])", name: "announcement_deliveries_status_check"
  end

  create_table "announcements", force: :cascade do |t|
    t.string "audience", null: false
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "emailed_at"
    t.bigint "organization_id", null: false
    t.boolean "pinned", default: false, null: false
    t.datetime "published_at"
    t.string "status", default: "draft", null: false
    t.bigint "target_event_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_announcements_on_author_id"
    t.index ["organization_id", "status", "pinned", "published_at"], name: "index_announcements_for_bulletin"
    t.index ["organization_id"], name: "index_announcements_on_organization_id"
    t.index ["target_event_id"], name: "index_announcements_on_target_event_id"
    t.check_constraint "audience::text = ANY (ARRAY['all_members'::character varying, 'officers'::character varying, 'event_rsvps'::character varying, 'event_attendees'::character varying]::text[])", name: "announcements_audience_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying]::text[])", name: "announcements_status_check"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.datetime "checked_in_at"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "marked_by_id"
    t.bigint "membership_id", null: false
    t.text "note"
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "membership_id"], name: "index_attendance_records_on_event_id_and_membership_id", unique: true
    t.index ["event_id"], name: "index_attendance_records_on_event_id"
    t.index ["marked_by_id"], name: "index_attendance_records_on_marked_by_id"
    t.index ["membership_id", "created_at"], name: "index_attendance_records_on_membership_id_and_created_at"
    t.index ["membership_id"], name: "index_attendance_records_on_membership_id"
    t.check_constraint "status::text = ANY (ARRAY['present'::character varying, 'late'::character varying, 'excused'::character varying, 'absent'::character varying]::text[])", name: "attendance_records_status_check"
  end

  create_table "events", force: :cascade do |t|
    t.integer "capacity"
    t.datetime "check_in_closes_at"
    t.string "check_in_code_digest"
    t.datetime "check_in_opens_at"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.datetime "ends_at"
    t.string "location"
    t.bigint "organization_id", null: false
    t.datetime "rsvp_deadline"
    t.datetime "starts_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_events_on_created_by_id"
    t.index ["organization_id", "check_in_opens_at", "check_in_closes_at"], name: "index_events_on_organization_and_check_in_window"
    t.index ["organization_id", "starts_at"], name: "index_events_on_organization_id_and_starts_at"
    t.index ["organization_id"], name: "index_events_on_organization_id"
    t.check_constraint "capacity IS NULL OR capacity > 0", name: "events_positive_capacity"
    t.check_constraint "check_in_opens_at IS NULL OR check_in_closes_at IS NULL OR check_in_closes_at > check_in_opens_at", name: "events_check_in_window_order"
    t.check_constraint "ends_at IS NULL OR ends_at > starts_at", name: "events_end_after_start"
    t.check_constraint "rsvp_deadline IS NULL OR rsvp_deadline <= starts_at", name: "events_deadline_before_start"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.bigint "invited_by_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "revoked_at"
    t.string "role", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index "organization_id, lower((email)::text)", name: "index_invitations_on_pending_organization_email", unique: true, where: "((accepted_at IS NULL) AND (revoked_at IS NULL))"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["token_digest"], name: "index_invitations_on_token_digest", unique: true
    t.check_constraint "role::text = ANY (ARRAY['owner'::character varying, 'officer'::character varying, 'coordinator'::character varying, 'member'::character varying]::text[])", name: "invitations_role_check"
  end

  create_table "memberships", force: :cascade do |t|
    t.boolean "announcement_emails_enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.boolean "event_reminder_emails_enabled", default: true, null: false
    t.bigint "organization_id", null: false
    t.boolean "recruitment_emails_enabled", default: true, null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_memberships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['owner'::character varying, 'officer'::character varying, 'coordinator'::character varying, 'member'::character varying]::text[])", name: "memberships_role_check"
  end

  create_table "organization_join_links", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "expires_at"
    t.string "label", null: false
    t.integer "max_uses"
    t.bigint "organization_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.integer "uses_count", default: 0, null: false
    t.index ["created_by_id"], name: "index_organization_join_links_on_created_by_id"
    t.index ["organization_id", "active"], name: "index_organization_join_links_on_organization_id_and_active"
    t.index ["organization_id"], name: "index_organization_join_links_on_organization_id"
    t.check_constraint "max_uses IS NULL OR max_uses > 0", name: "join_links_positive_max_uses"
    t.check_constraint "uses_count >= 0", name: "join_links_nonnegative_uses_count"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.string "current_semester_label"
    t.text "description"
    t.string "meeting_note"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["archived_at"], name: "index_organizations_on_archived_at"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "rsvps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "membership_id", null: false
    t.text "note"
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "membership_id"], name: "index_rsvps_on_event_id_and_membership_id", unique: true
    t.index ["event_id"], name: "index_rsvps_on_event_id"
    t.index ["membership_id"], name: "index_rsvps_on_membership_id"
    t.check_constraint "status::text = ANY (ARRAY['attending'::character varying, 'maybe'::character varying, 'not_attending'::character varying]::text[])", name: "rsvps_status_check"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email_address)::text)", name: "index_users_on_lower_email_address", unique: true
  end

  add_foreign_key "announcement_deliveries", "announcements"
  add_foreign_key "announcement_deliveries", "memberships"
  add_foreign_key "announcement_deliveries", "users"
  add_foreign_key "announcements", "events", column: "target_event_id"
  add_foreign_key "announcements", "organizations"
  add_foreign_key "announcements", "users", column: "author_id"
  add_foreign_key "attendance_records", "events"
  add_foreign_key "attendance_records", "memberships"
  add_foreign_key "attendance_records", "users", column: "marked_by_id"
  add_foreign_key "events", "organizations"
  add_foreign_key "events", "users", column: "created_by_id"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "organization_join_links", "organizations"
  add_foreign_key "organization_join_links", "users", column: "created_by_id"
  add_foreign_key "rsvps", "events"
  add_foreign_key "rsvps", "memberships"
end
