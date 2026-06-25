# Tabled

Tabled is a production-minded Ruby on Rails application for student organizations to manage rosters, gatherings, attendance, announcements, reports, and semester records.

It was built as a portfolio-quality Rails app focused on realistic student organization operations: keeping rosters current, inviting members, recording RSVPs and check-ins, communicating with members, exporting semester records, and giving future officers a readable handoff.

## Screenshots

Screenshots coming soon.

Planned captures:

- Organization dashboard
- Member roster and member record
- Gathering detail and attendance sheet
- Bulletin
- Semester report
- Organization Log Book

See [docs/screenshots](docs/screenshots) for the screenshot capture plan.

## Why I built this

Student organizations often run on spreadsheets, group chats, copied forms, and institutional memory. Tabled explores what a focused, campus-native operations tool could look like for officers who need to keep a semester moving without turning club work into generic business software.

The project is also a production-minded Rails portfolio piece: it goes beyond simple CRUD with role-based access, organization scoping, CSV import/export, attendance workflows, public demo protections, and deployment-oriented configuration.

## Core features

- Multi-tenant organization workspaces with owner, officer, coordinator, and member roles
- Member rosters with search, filtering, pagination, and individual member records
- Email invitations, secure invitation acceptance, and reusable member-only join links
- CSV roster import that creates pending invitations and reports skipped or invalid rows
- Gatherings with RSVPs, capacity/deadline behavior, self check-in windows, manual attendance, attendance notes, and CSV exports
- Member-facing attendance history and organization-scoped communication preferences
- Bulletin announcements with all-member, officer, RSVP, and checked-in attendee audiences
- Optional announcement email delivery with delivery records and preference-based skips
- Semester reports with roster, participation, and event summary CSV exports
- Workspace administration: settings, ownership transfer, leave flow, archive/restore, and permanent deletion for archived organizations
- Organizer-only Log Book/activity trail for important member, gathering, attendance, announcement, report, and settings activity
- Small public demo seed, read-only public demo mode, and an opt-in large demo seed for screenshots and pagination testing

## Tech stack

- Ruby 3.4.9
- Rails 8.1.3
- PostgreSQL
- Hotwire: Turbo and Stimulus
- Tailwind CSS via `tailwindcss-rails`
- Import maps and Propshaft
- Solid Queue, Solid Cache, and Solid Cable
- Minitest, Capybara, and Selenium
- RuboCop, Brakeman, and Bundler Audit
- Dockerfile and Kamal deployment configuration

## Local setup

Install Ruby 3.4.9 and PostgreSQL. Make sure PostgreSQL is running, then:

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

Open [http://localhost:3000](http://localhost:3000).

The default seed creates a Buckeye Film Society demo workspace. Sign in with:

- Email: `demo-owner@example.test`
- Password: `tabled-demo-password`

Development email delivery is file-based; messages are written under `tmp/mails`.

## Seed data

The default seed is the small demo seed:

```bash
bin/rails db:seed
```

It creates a believable Buckeye Film Society workspace with members, roles, invitations, recruitment links, gatherings, RSVP and attendance records, bulletin posts, delivery records, Log Book entries, and one archived demo organization.

For local screenshots, pagination checks, and large-roster UI testing, load the opt-in large demo seed:

```bash
SEED=large_demo bin/rails db:seed
# or
bin/rails seed:large_demo
```

The large seed creates deterministic fake campus data. It is blocked in production unless `ALLOW_LARGE_DEMO_SEED=true` is set intentionally.

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

## Environment variables

Local development works without extra environment variables when PostgreSQL is available.

| Variable | Purpose |
| --- | --- |
| `RAILS_MASTER_KEY` | Decrypts Rails credentials in production. Never commit `config/master.key`. |
| `TABLED_DATABASE_PASSWORD` | PostgreSQL password used by the production database config. |
| `TABLED_HOST` | Canonical production host for host authorization and generated mailer links. |
| `TABLED_PROTOCOL` | Protocol for generated mailer links, usually `https`. |
| `TABLED_ASSUME_SSL` | Controls `config.assume_ssl`; defaults to `true` in production. |
| `TABLED_FORCE_SSL` | Controls `config.force_ssl`; defaults to `true` in production. |
| `TABLED_PUBLIC_DEMO` | Set to `true` for the public portfolio demo so seeded demo accounts are read-only. |
| `TABLED_SOLID_QUEUE_IN_PUMA` | Set to `true` only after Solid Queue tables are prepared and Puma should run the queue supervisor. |
| `RAILS_LOG_LEVEL` | Rails log level; defaults to `info`. |
| `RAILS_MAX_THREADS` | Puma thread count and database max connection baseline. |
| `WEB_CONCURRENCY` | Optional Puma worker process count. |
| `JOB_CONCURRENCY` | Optional Solid Queue process count. |
| `PORT` | Runtime port used by Puma; defaults to `3000`. |
| `SEED` | Selects a seed file, such as `large_demo`; defaults to `demo`. |
| `ALLOW_LARGE_DEMO_SEED` | Must be `true` to run the large demo seed in production. |

Optional SMTP settings can be added through environment variables or Rails credentials. The current production configuration documents SMTP but does not commit a provider or secrets.

## Deployment notes

The repository includes a production Dockerfile and Kamal configuration.

For Kamal-style deployment:

1. Replace the placeholder image, server, registry, and host values in `config/deploy.yml`.
2. Export required secrets or add them to your deployment secret manager:

   ```bash
   export RAILS_MASTER_KEY=...
   export TABLED_DATABASE_PASSWORD=...
   ```

3. Confirm `TABLED_HOST` matches the public hostname.
4. Run `bin/kamal setup` for the first deploy.
5. Run `bin/kamal deploy` for later deploys.

The `/up` health check is available for platform probes. Production uses Solid Queue, Solid Cache, and Solid Cable with separate configured databases. Active Storage uses local disk in the current demo deployment; a durable object store can be added later if uploads become part of the product.

Railway deployment is also supported by the app shape: use the Dockerfile or Rails service, provide production environment variables, attach PostgreSQL, and run the same database and demo tasks described below.

## Public demo maintenance

For a public resume/portfolio deployment, set:

```bash
TABLED_PUBLIC_DEMO=true
```

Then seed the demo workspace once:

```bash
bin/rails db:seed
```

Seeded demo accounts are marked read-only in public demo mode. Visitors can sign in and explore the workspace, but unsafe changes are blocked so the shared demo stays intact.

To keep the demo from aging as calendar dates move forward, refresh the public demo workspace periodically:

```bash
bin/rails demo:refresh
```

This reloads the small demo workspace with current relative dates, including upcoming gatherings, recent past gatherings, RSVP deadlines, announcement timestamps, and Log Book timestamps. It is safe to run repeatedly for the demo workspace.

On Railway, run `bin/rails demo:refresh` manually after deploys or from a scheduled job if you want the public demo to stay fresh without manual upkeep. Keep `TABLED_SOLID_QUEUE_IN_PUMA=false` or unset until the Solid Queue production tables are prepared.

## Architecture notes

- Organization scoping is enforced through slug-based lookup, membership checks, and organization-scoped associations.
- Authorization is role-based: owners and officers manage most organization operations; coordinators help with organizer workflows; members receive member-facing access.
- Invitations store secure token digests. Reusable join links use signed IDs instead of persisted raw tokens.
- RSVP records are separate from attendance records, so intent and actual participation can differ.
- Check-in codes are digest-backed and only shown when opened or regenerated.
- Announcements support all-member, officer, event RSVP, and checked-in attendee audiences. Email delivery respects membership-scoped communication preferences.
- Roster import, report exports, attendance exports, and member records are organization-scoped and authorization-protected.
- Activity logging goes through `ActivityLog`, stores readable summaries, and filters sensitive metadata keys.
- Public demo mode blocks unsafe requests for seeded demo accounts while leaving normal users and read-only browsing available.
- Archived organizations keep their records, block new activity, remain visible from the organizations page, and can be permanently deleted by owners.

## Known limitations and future work

- Production SMTP provider setup is not included yet.
- Local Active Storage is used for the current demo deployment.
- Recurring gatherings, QR-code generation, calendar integrations, attachments, charts, XLSX import, read receipts, social profiles, avatars, bios, and public user profile pages are intentionally out of scope.
- Existing production-style records are not historically backfilled into the Log Book.
- Check-in codes are shown only when opened or regenerated; Tabled does not retain a recoverable raw code.

## Repository metadata

Suggested GitHub description:

> Production-minded Rails app for student organizations to manage rosters, gatherings, attendance, announcements, reports, and semester records.

Suggested GitHub topics:

`ruby-on-rails`, `rails`, `postgresql`, `tailwindcss`, `student-organizations`, `attendance-tracking`, `role-based-access-control`, `csv-import-export`, `portfolio-project`

See [docs/project_brief.md](docs/project_brief.md) for broader product and visual direction.
