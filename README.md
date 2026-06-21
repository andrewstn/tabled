# Tabled

Tabled is a production-minded Ruby on Rails application where student organizations and small teams manage the practical work of a semester: members, officers, events, attendance, announcements, and internal operations.

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

The seed is idempotent and also creates officer, coordinator, and member accounts for Buckeye Film Society.

## Tests and checks

Run the full test suite:

```bash
bin/rails test
```

Run style and security checks with:

```bash
bin/rubocop
bin/brakeman --no-pager
```

## Current scope

Milestone 1 establishes the multi-tenant organization foundation:

- Account signup and session authentication
- Organizations with stable, human-readable URLs
- Memberships with owner, officer, coordinator, and member roles
- Transactional organization creation
- Organization dashboards and workspace switching
- Membership-scoped access and manager-only settings
- Idempotent local demo data

Invitations, the member directory, events, RSVPs, check-ins, announcements, and activity history belong to later milestones.

## Product and visual direction

Tabled should feel like a shared meeting table, club office, campus bulletin board, and well-kept organization binder. The interface uses warm paper surfaces, moss and amber accents, readable type, tactile controls, and specific campus language. Keep future work operational and human; avoid sterile SaaS dashboards, generic metric cards, glass effects, AI-style gradients, and vague productivity copy.

See [docs/project_brief.md](docs/project_brief.md) for the broader product brief.
