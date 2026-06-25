# Screenshot plan

Screenshots are intentionally not committed until final public demo data and viewport choices are stable.

Recommended captures for the GitHub README:

1. Organization dashboard — owner view with upcoming gatherings, active notes, bulletin preview, and recent activity.
2. Member roster — large enough to show search, filters, pagination, roles, and member records.
3. Gathering detail — RSVP controls, check-in state, and attendance status.
4. Attendance sheet — organizer view with grouped RSVP dropdowns and manual attendance controls.
5. Bulletin — chronological member-facing announcements with pagination.
6. Semester report — participation summary and CSV export actions.
7. Log Book — organizer-only activity record.

Suggested workflow:

```bash
SEED=large_demo bin/rails db:seed
bin/dev
```

Sign in as `demo-owner@example.test` / `tabled-demo-password`, capture at a desktop viewport, and remove or blur any local-only browser chrome before committing images.

When screenshots are ready, place optimized PNG or WebP files in this directory and update the README screenshot section with relative links.
