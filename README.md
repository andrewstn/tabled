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

The seed is idempotent and also creates officer, coordinator, and member accounts plus two pending invitations for Buckeye Film Society.

Invitation emails stay local in development and are written beneath `tmp/mails`.

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

Milestones 1 and 2 establish the multi-tenant organization and member-onboarding foundation:

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
- Idempotent local demo data

Dashboard sections for gatherings, attendance, announcements, and activity are intentional empty states for now. Events, RSVPs, check-ins, organization announcements, and activity history belong to later milestones.

## Product and visual direction

Tabled should feel like a shared meeting table, club office, campus bulletin board, and well-used organization binder. The interface uses warm paper surfaces, moss and amber accents, readable type, tactile controls, and specific campus language. Keep future work active, practical, and human—not archival or bureaucratic—and avoid generic SaaS cards, glass effects, AI-style gradients, and vague productivity copy.

See [docs/project_brief.md](docs/project_brief.md) for the broader product brief.
