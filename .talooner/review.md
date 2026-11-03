# Review guidelines

Repo-wide, alongside `rules.tln` and the guides in `docs/guides/`.

- This is a public gem that can sign anyone in as any role. Every change is
  read first for what it does to the token guard and the production guard.
- The hooks' JSON is a contract with talooner-qa (README, "The hooks"). A
  change to a request or answer lands in talooner-qa's client in step.
- Nothing defaults to passing: an unconfigured hook is `404`, a bad request
  `422`, a check answers only an explicit `true` or `false`.
- User-visible text (error messages, README examples) ships with a spec.
- Supported: Ruby ≥ 3.4, Rails ≥ 7.2. CI tests every combination; a new
  Rails release is added to the matrix before the gemspec allows it.
- A release is a `v*.*.*` tag matching `TaloonerQa::VERSION`, with a
  `CHANGELOG.md` entry. CI publishes it; nobody pushes a gem by hand.
