# Guide: `lib/talooner_qa/`

What only the app knows (`Configuration`), and how pages and seeds are built
from it. Ruby ≥ 3.4 (`it` block parameters), Rails ≥ 7.2.

## Configuration

- Every hook's part is optional. A missing part makes its hook answer `404`;
  it never raises at boot and never invents a default that could pass a check.
- Named seeds win over sources, then sources in the order they were configured.

## Seeds

- Seed names are opaque to talooner-qa. FactoryBot gives `factory` and
  `factory:trait`, one trait per name; a combination worth testing is worth its
  own trait.
- `Seeds.attributes` returns scalars only: strings, numbers, booleans, times as
  ISO 8601. Nested values are dropped.
- Secrets are **left out, not masked**: `ALWAYS_FILTERED` plus the app's
  `filter_parameters`. Removing a key from `ALWAYS_FILTERED` needs a reason in
  the PR; a secret that slips through lands in QA logs.
- `param` is the record's `to_param`, so a page's `:id` can be filled.

## Pages

- Named `GET` routes only, `(.:format)` stripped, the hooks' own and Rails'
  internal routes excluded. The route name is what the decision model answers
  about, so the first route with a name wins.

## Style

- Comments say why, matching the surrounding code. RuboCop (`.rubocop.yml`) is
  the style; `bundle exec rubocop` must be clean.
- New user-visible text (error messages) ships with a request spec asserting it.
