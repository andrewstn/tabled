# Product copy audit

This cleanup pass keeps Tabled’s record-book, club-binder, and bulletin-board identity while making transactional copy plainer.

## Search terms reviewed

- `around the table`
- `pull up a chair`
- `bring someone to the table`
- `save your place`
- `chair`
- `table`
- `roster`

## Areas reviewed

- Controllers and services for flash messages and validation errors
- Views for headings, helper text, empty states, and calls to action
- Mailer templates and mailer subjects
- Seeds, fixtures, controller tests, mailer tests, and system tests
- README and project documentation

## Cleanup targets

- Remove forced table metaphors from success messages, errors, helper text, and emails.
- Keep `roster`, `bulletin`, `attendance sheet`, `log book`, and `current semester` where they are concrete product terms.
- Use `around the table` only where it works as a section label, not as a transactional phrase.
- Make recruitment link copy practical: joining, account creation, link availability, limits, and membership status.
