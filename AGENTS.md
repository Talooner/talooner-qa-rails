# talooner-qa-rails

A public Rails engine serving the test-only `/__qa/*` API that Talooner QA
(`talooner-qa`) drives. The JSON contract is talooner-qa's `docs/hooks.md`;
the README's "The hooks" table is its public copy. Change both together.

## Layout

| Path | |
|---|---|
| `app/controllers/talooner_qa/` | `HooksController`: one action per hook, token guard |
| `lib/talooner_qa.rb` | `configure`, `enabled?`, the token and production guards |
| `lib/talooner_qa/` | `Configuration`, `Pages` (from the router), `Seeds` (sources, attribute filter) |
| `spec/dummy.rb` | the smallest Rails app the engine mounts in: in-memory SQLite, a factory with a trait |
| `docs/guides/` | the guides `.talooner/architecture.yaml` reviews each unit against |

## Commands

| | |
|---|---|
| `bundle exec rspec` | the specs; `RAILS_VERSION="~> 8.0.0"` to try another Rails |
| `bundle exec rubocop` | style |
| `gem build talooner-qa-rails.gemspec` | the package CI builds |

Ruby ≥ 3.4 (the code uses `it`). Locally: `PATH=~/.rbenv/versions/4.0.6/bin:$PATH`.

## Gotchas

- `/__qa/login` signs in as any role. `authenticate!` guards every action; never
  skip it, and keep the 404-when-disabled behaviour.
- Seeds leave secrets out rather than masking them. Don't shrink `ALWAYS_FILTERED`.
- In the controller the configuration is `qa`, never `config` (that is Rails').
- Public repo, public gem: commits are authored `Talooner <dev@talooner.com>`
  (repo-local git config). Releases go out from CI on a `v*.*.*` tag through
  rubygems trusted publishing; nobody runs `gem push`.

## Conventions

- Comments carry the why; match the file.
- New user-visible text (error messages) gets a request spec asserting it.
- Commit messages are one line.
