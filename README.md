# Tabled

Tabled is a production-minded Ruby on Rails application for student organizations and small teams to manage members, roles, events, attendance, announcements, and internal operations.

The project is designed to demonstrate production Rails development through multi-tenant organization workspaces, role-based authorization, invitation-based onboarding, event attendance workflows, background jobs, email delivery, audit logging, CSV import/export, tests, CI, and deployment.

## Stack

- Ruby on Rails
- PostgreSQL
- Hotwire / Turbo
- Stimulus
- Tailwind CSS

## Current scope

Milestone 1 focuses on the organization foundation:

- Authentication
- Organizations
- Memberships
- Roles
- Organization-scoped access
- Organization dashboard
- Local seed data

## Local setup

```bash
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/dev
