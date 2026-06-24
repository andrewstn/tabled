# Tabled

Tabled is a production-minded Ruby on Rails application for the practical work of a student organization semester: members, officers, meetings, attendance, announcements, and internal operations.

## Stack

- Ruby 3.4.9
- Rails 8.1.3
- PostgreSQL
- Hotwire (Turbo and Stimulus)
- Tailwind CSS

## Local setup

Install Ruby 3.4.9 and PostgreSQL, make sure PostgreSQL is running, then:

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

Open [http://localhost:3000](http://localhost:3000). The seed data includes an owner account for local exploration:

- Email: `demo-owner@example.test`
- Password: `tabled-demo-password`

The seed is idempotent and also creates a 32-person roster, organization settings data, multiple owners/officers, varied communication preferences, two pending invitations, four gatherings, varied RSVP and attendance records, all-member/officer/event-targeted bulletin posts, an officer draft, announcement delivery records, activity log entries, active and closed recruitment links for Buckeye Film Society, and one archived demo organization hidden from normal workspace lists. The larger roster makes pagination, attendance filters, semester reports, communication preferences, settings, the Log Book, and CSV exports visible immediately.

To try recruitment locally, sign in as the demo owner, open **Member roster → Recruitment links**, and copy the active Autumn Involvement Fair URL. Open that URL in a private browser window to follow the sign-up and join flow. Reusable links always add members; they cannot grant elevated roles. QR generation is intentionally not included yet.

To try reporting locally, sign in as the demo owner and open **Semester report** from the organization dashboard or member roster. Use the report actions to download roster, participation, or event summary CSV files.

To try communication preferences locally, sign in as any demo member and open **Communication preferences** from the organization dashboard. These settings are scoped to that member’s Buckeye Film Society membership.

To try targeted announcement audiences, sign in as the demo owner and open **Bulletin → Post announcement**. Choose All members, Officers, Event RSVPs, or Checked-in attendees. Event audiences require a selected gathering. If you choose to email a published announcement, delivery records are created for sent and skipped recipients based on members’ announcement email preferences.

To try workspace administration, sign in as the demo owner and open **Organization settings**. You can update organization details, transfer ownership to another current member, archive the organization, or restore an archived organization. The previous owner remains an owner after transfer. Archived organizations keep their records but block new activity and are hidden from normal workspace lists.

To try the Log Book, sign in as the demo owner and open **Log book** from the Recent activity dashboard section. Owners, officers, and coordinators can view the organization-wide record of important changes; regular members cannot view the full Log Book.

To try account settings, use **Account settings** in the signed-in header. This page only updates the account name used across organizations; social profiles, avatars, bios, and public user pages are intentionally out of scope.

To try roster import locally, open **Member roster → Import roster** and upload a CSV with these headers:

```csv
name,email,role
Sample Member,sample.member@example.test,member
Sample Coordinator,sample.coordinator@example.test,coordinator
```

The import creates pending invitations for valid rows. Rows for existing members or duplicate pending invitations are skipped. Blank roles default to `member`; `owner` rows are rejected.

Invitation and optional announcement emails stay local in development and are written beneath `tmp/mails`.

## Tests and checks

Run the full test suite:

```bash
bin/rails test
```

Run browser-backed system tests with:

```bash
bin/rails test:system
```

Run style and security checks with:

```bash
bin/rubocop
bin/brakeman --no-pager
```

## Current scope

Milestones 1 through 10 establish the multi-tenant organization workspace, active semester calendar, event sign-in record, organization bulletin, practical large-roster recruitment workflow, semester reporting, CSV exports, roster import, communication preferences, event-targeted announcements, delivery records, workspace administration, and organization Log Book:

- Account signup and session authentication
- Organizations with stable, human-readable URLs
- Memberships with owner, officer, coordinator, and member roles
- Transactional organization creation
- Organization dashboards and workspace switching
- Membership-scoped access and manager-only settings
- A member directory with joined dates and roles
- Owner/officer role management and member removal
- Expiring, revocable invitations with secure token digests
- Invitation acceptance for existing users and new account signup
- Development-safe invitation email delivery
- Organization-scoped upcoming and past gatherings
- Owner/officer event management, with coordinator create/edit access
- Member RSVP choices for attending, maybe, and not attending
- Capacity and RSVP-deadline enforcement with organizer overrides
- Private organizer event rosters and response summaries
- Real upcoming gathering data on the organization dashboard
- Organizer attendance sheets with present, late, excused, and absent records
- Manual attendance marking with arrival times, notes, and the marking organizer
- Digest-backed, time-limited member self check-in codes
- Organization-scoped member attendance history
- Organizer-only event attendance CSV export
- Real attendance follow-ups and recent roll calls on the dashboard
- Organization bulletins with pinned and recent announcements
- Private officer drafts and officers-only posts
- Owner/officer announcement drafting, publishing, editing, and removal
- Optional audience-scoped announcement email delivery
- Real bulletin content on the organization dashboard
- Database-backed member roster search and role filtering
- RSVP and attendance-status filtering for attendance sheets
- Stable, query-preserving pagination for roster and attendance workflows
- Reusable member-only recruitment links with expiration, use limits, and organizer controls
- Public join pages with sign-in and account-creation return paths
- Organizer-only semester reports with member participation and event summaries
- Roster, participation, and event summary CSV exports
- CSV roster import that creates pending invitations and reports skipped or invalid rows
- Membership-scoped communication preferences
- Event-targeted announcement audiences for RSVP and checked-in attendee groups
- Announcement email delivery previews and organizer-visible delivery summaries
- Delivery records for sent and preference-skipped announcement emails
- Practical organization settings and read-only workspace slugs
- Owner-only ownership transfer that keeps the previous owner in place
- Self-service leave organization flow with last-owner protection
- Owner-only archive and restore flows for organization workspaces
- Minimal account settings for editing account name
- Organization-scoped member records for roster and attendance context
- Organization-scoped Log Book entries for important member, gathering, attendance, announcement, report, and settings activity
- Organizer-only Log Book visibility for owners, officers, and coordinators
- Idempotent local demo data

Activity logging records readable summaries for important organization actions, but it intentionally avoids raw invitation tokens, recruitment link tokens, passwords, check-in codes, and sensitive credentials. Existing production-style records are not historically backfilled; activity appears for actions recorded after the Log Book feature exists, plus local demo seed entries.

Event reminder scheduling, digest emails, push notifications, SMS, comments, reactions, attachments, production email providers, recurring events, QR-code generation, geolocation, complex analytics, calendar integrations, persistent import batches, XLSX import, automatic import emails, charts, read receipts, social-style profiles, avatars, bios, public user profile pages, and historical activity backfill are intentionally outside the current scope. Check-in codes are shown only when opened or regenerated; Tabled does not retain a recoverable raw code.

## Product and visual direction

Tabled should feel like a club office, campus bulletin board, practical sign-in sheet, and well-used organization binder. The interface uses warm paper surfaces, moss and amber accents, readable type, tactile controls, and specific campus language. Keep future work active, practical, and human—not archival or bureaucratic—and avoid generic SaaS cards, glass effects, AI-style gradients, and vague productivity copy.

See [docs/project_brief.md](docs/project_brief.md) for the broader product brief.
