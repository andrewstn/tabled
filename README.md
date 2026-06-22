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

The seed is idempotent and also creates a 32-person roster, two pending invitations, four gatherings, varied RSVP and attendance records, two published bulletin posts, an officer draft, and active and closed recruitment links for Buckeye Film Society. The larger roster makes pagination and attendance filters visible immediately.

To try recruitment locally, sign in as the demo owner, open **Member roster → Recruitment links**, and copy the active Autumn Involvement Fair URL. Open that URL in a private browser window to follow the sign-up and join flow. Reusable links always add members; they cannot grant elevated roles. QR generation is intentionally not included yet.

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

Milestones 1 through 6 establish the multi-tenant organization workspace, active semester calendar, event sign-in record, organization bulletin, and practical large-roster recruitment workflow:

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
- Idempotent local demo data

Event-attendee announcement targeting, comments, reactions, attachments, notification preferences, production email providers, recurring events, QR-code generation, geolocation, complex analytics, calendar integrations, and activity history are intentionally outside the current scope. Check-in codes are shown only when opened or regenerated; Tabled does not retain a recoverable raw code.

## Product and visual direction

Tabled should feel like a shared meeting table, club office, campus bulletin board, and well-used organization binder. The interface uses warm paper surfaces, moss and amber accents, readable type, tactile controls, and specific campus language. Keep future work active, practical, and human—not archival or bureaucratic—and avoid generic SaaS cards, glass effects, AI-style gradients, and vague productivity copy.

See [docs/project_brief.md](docs/project_brief.md) for the broader product brief.
