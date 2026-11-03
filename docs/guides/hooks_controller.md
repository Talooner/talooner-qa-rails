# Guide: `app/controllers/talooner_qa/`

`HooksController` serves `/__qa/*` to talooner-qa (README, "The hooks"). It can
sign anyone in as any role, so this is the code where a mistake becomes a
backdoor into every app that mounts the gem.

## The token guards every action

- `authenticate!` runs before every action, with no `skip_before_action` for
  any of them. A new action gets it by default; never opt one out.
- The comparison is `ActiveSupport::SecurityUtils.secure_compare`, never `==`.
- With the hooks disabled (no `TALOONER_QA_HOOK_TOKEN`, or production without
  `TALOONER_QA_ALLOW_PRODUCTION=1`) every action answers `404`, as if nothing
  were mounted. A wrong token answers `401`.
- No response or error message echoes the token or the `Authorization` header.

## Answers follow the contract

- A hook whose part the app did not configure answers `404` (`not_configured`):
  talooner-qa reads that as "not implemented" and falls back for roles and pages.
- A bad request (unknown seed, unknown check, login without roles) answers `422`
  with `{"error": "..."}` naming what to fix. Never `200` with an empty body.
- `check` answers only an explicit `{"ok": true|false}`. A block returning
  anything else is a `422`, never a pass or a silent failure.
- `login` never runs for an empty role set: a guest does not log in.

## Rails

- `ActionController::Base`, not `API`: login must set the app's session cookie.
- `skip_forgery_protection` is safe only because the token is the authentication.
- The configuration helper is `qa`, never `config`: that name is the
  controller's own, and shadowing it breaks the logger.
