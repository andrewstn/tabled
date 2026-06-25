# Tabled

Tabled is a production-minded Ruby on Rails app for student organizations to manage rosters, gatherings, attendance, announcements, reports, and semester records.

It is built as a portfolio-quality Rails application for the kind of operational work student officers actually inherit: keeping rosters current, inviting members, checking people in, communicating clearly, preserving reports, and handing the next officer team a readable record.

## Screenshots

Screenshots are not committed yet. Planned captures:

- Organization dashboard
- Member roster and member record
- Gathering detail and attendance sheet
- Bulletin
- Semester report
- Organization Log Book

See [docs/screenshots](docs/screenshots) for the capture plan.

## Why this exists

Most student organizations run on a mix of spreadsheets, group chats, copied forms, and institutional memory. Tabled explores what a focused, campus-native operations tool could look like: practical enough for busy officers and structured enough to survive leadership turnover.

## Core features

- Organization workspaces with owner, officer, coordinator, and member roles
- Member rosters, member records, invitations, reusable join links, and CSV roster import
- Gatherings with RSVPs, check-in windows, manual attendance, attendance notes, and CSV exports
- Member-facing attendance history and communication preferences
- Bulletin posts with audience targeting and email delivery records
- Semester reports with roster, participation, and event summary exports
- Workspace administration: settings, ownership transfer, leave flow, archive/restore, and permanent deletion for archived organizations
- Organizer-only Log Book entries for important member, gathering, attendance, announcement, report, and settings activity

## Tech stack

- Ruby 3.4.9
- Rails 8.1.3
- PostgreSQL
- Hotwire: Turbo and Stimulus
- Tailwind CSS through `tailwindcss-rails`
- Solid Queue, Solid Cache, and Solid Cable
- Minitest, Capybara, Selenium, RuboCop, Brakeman, and Bundler Audit
- Docker and Kamal deployment configuration

## Local setup

Install Ruby 3.4.9 and PostgreSQL. Make sure PostgreSQL is running, then:

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

Open [http://localhost:3000](http://localhost:3000).

The default seed creates a small Buckeye Film Society demo workspace. Sign in with:

- Email: `demo-owner@example.test`
- Password: `tabled-demo-password`

Development emails are written under `tmp/mails`.

## Seed data

The default seed is intentionally small and idempotent:

```bash
bin/rails db:seed
```

It creates a polished demo organization with members, roles, invitations, recruitment links, gatherings, RSVP and attendance records, bulletin posts, delivery records, activity log entries, and one archived demo organization.

For local screenshots, pagination checks, and large-roster UI testing, load the opt-in large demo seed:

```bash
SEED=large_demo bin/rails db:seed
# or
bin/rails seed:large_demo
```

The large seed creates deterministic fake data only. It is guarded from accidental production use unless `ALLOW_LARGE_DEMO_SEED=true` is set intentionally.

## Environment variables

Local development works without extra environment variables when PostgreSQL is available.

Production-style deploys should provide:

- `RAILS_MASTER_KEY` — decrypts Rails credentials; never commit `config/master.key`
- `TABLED_DATABASE_PASSWORD` — production PostgreSQL password
- `TABLED_HOST` — canonical production host for host authorization and mailer links
- `TABLED_PROTOCOL` — usually `https`
- `TABLED_ASSUME_SSL` — defaults to `true`
- `TABLED_FORCE_SSL` — defaults to `true`
- `RAILS_LOG_LEVEL` — defaults to `info`
- `SOLID_QUEUE_IN_PUMA` — `true` for the simple single-server Kamal setup

Optional SMTP settings can be added through environment variables or Rails credentials. The current production configuration documents SMTP but does not commit a provider or any secrets.

## Tests and checks

Run the Rails test suite:

```bash
bin/rails test
```

Run browser-backed system tests:

```bash
bin/rails test:system
```

Run style, security, and dependency checks:

```bash
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
```

## Deployment notes

The repository includes a production Dockerfile and Kamal configuration.

Before deploying:

1. Replace the placeholder image, server, registry, and host values in `config/deploy.yml`.
2. Export required secrets or add them to your deployment secret manager:

   ```bash
   export RAILS_MASTER_KEY=...
   export TABLED_DATABASE_PASSWORD=...
   ```

3. Confirm `TABLED_HOST` matches the public hostname.
4. Run `bin/kamal setup` for the first deploy.
5. Run `bin/kamal deploy` for later deploys.

The `/up` health check is available for platform probes. Production uses Solid Queue, Solid Cache, and Solid Cable with separate configured databases. Local Active Storage is deliberate for the current portfolio/demo deployment; a durable object store can be added later if user uploads become part of the product.

Only run `bin/kamal app exec "bin/rails db:seed"` in an environment where the small demo workspace is desired. Do not run the large demo seed in production unless that is intentional and `ALLOW_LARGE_DEMO_SEED=true` is set.

## Architecture notes

- Organization scoping is enforced through slug-based lookup, membership checks, and organization-scoped associations.
- Authorization is role-based: owners and officers manage most operations; coordinators help with organizer workflows; members receive member-facing access.
- Invitations store secure token digests. Reusable join links use signed IDs instead of persisted raw tokens.
- Attendance separates organizer-marked records from member self check-in.
- Announcements support all-member, officers, event RSVP, and checked-in attendee audiences.
- Activity logging goes through `ActivityLog`, stores readable summaries, and filters sensitive metadata keys.
- Archived organizations keep their records, block new activity, remain reachable from the organizations page, and can be permanently deleted by owners.

## Known limitations and future work

- Production SMTP provider setup is not included yet.
- Local Active Storage is used for the current demo deployment.
- Recurring events, QR-code generation, calendar integrations, attachments, charts, XLSX import, read receipts, social profiles, avatars, bios, and public user profile pages are intentionally out of scope.
- Existing production-style records are not historically backfilled into the Log Book.
- Check-in codes are shown only when opened or regenerated; Tabled does not retain a recoverable raw code.
