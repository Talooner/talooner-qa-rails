# Talooner onboarding spec

Copied from `talooner-qa/.talooner/` (same rules, critical paths mapped to this gem).

## Sensitive paths

Changes here wait for a review before merge. No assignee: no `CODEOWNERS`, and a
team review request with `GITHUB_TOKEN` fails with a 422.

- `.talooner/`: the review policy itself
- `app/controllers/talooner_qa/`, `lib/talooner_qa.rb`: the token and production guards
- `lib/talooner_qa/seeds.rb`: what a seed may return; a secret here lands in QA logs
- `talooner-qa-rails.gemspec`, `.github/workflows/release.yml`: what ships to rubygems.org

## Extra rules

Same as `talooner`: description required, 1500+ lines need a human, new
dependencies need a security review, pending checks get a comment, an
inconclusive or failed AI review blocks, decision model gated at ≥0.85.

## AI review

on: provider anthropic, model claude-haiku-5-5.

## Decision model

on: SubQ Snap, `subq-snap-preview`, via `CDM_URL` / `CDM_TOKEN`.

## Guides

- `app/controllers/talooner_qa/`: docs/guides/hooks_controller.md
- `lib/talooner_qa/`: docs/guides/library.md

## Notes

- Advice mode on: blocking verdicts exit 0 and write no `REQUEST_CHANGES`.
- `pr.tests_passing` / `pr.lint_passing` map to the `test` and `lint` jobs in
  `.github/workflows/ci.yml`.
