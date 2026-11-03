# talooner-qa-rails

The test-only `/__qa/*` API that [Talooner](https://talooner.com) QA drives in a
Rails app. Talooner QA runs a PR's scenarios against a preview of the app; this
engine is how the app tells it what exists (roles, pages, data) and lets it act
(sign in as a role, seed a record, flip a flag, check the backend).

You write no step definitions. Pages come from your router, data from your
FactoryBot factories or your own seed script, roles from one block you write.

## Install

```ruby
# Gemfile: only where a preview or test runs
gem "talooner-qa-rails", group: %i[test preview]
```

```ruby
# config/routes.rb
mount TaloonerQa::Engine, at: "/__qa" if TaloonerQa.enabled?
```

`TaloonerQa.enabled?` is true only when `TALOONER_QA_HOOK_TOKEN` is set, and
never in production unless `TALOONER_QA_ALLOW_PRODUCTION=1` too. Every request
must carry `Authorization: Bearer $TALOONER_QA_HOOK_TOKEN`; without the token
every hook answers `404`.

> **`/__qa/login` signs in as any role.** Treat the token like a production
> secret, and never mount the engine where real users' data lives.

## Configure

```ruby
# config/initializers/talooner_qa.rb
TaloonerQa.configure do |qa|
  # {area => [role, ...]}: what /__qa/roles answers.
  qa.roles { { inventory: %w[user_reduced user_extended admin], tickets: %w[agent] } }

  # A user with exactly these roles ({"inventory" => "admin"}), and no access
  # elsewhere. Signed in with Devise's sign_in, unless you set qa.sign_in.
  qa.user_for { |roles| QaUsers.with_roles(roles) }

  # Every factory as "order" and every trait as "order:paid".
  qa.seeds_from_factory_bot(attributes: ->(_factory) { { account: QaAccount.current } })

  # A seed script that names what it builds, exposed by key.
  qa.seeds(names: -> { Manifest.keys }, seed: ->(name) { Manifest.record(name) })

  # One-offs; a named seed wins over a factory of the same name.
  qa.seed("big_order") { FactoryBot.create(:order, :paid, items_count: 50) }

  qa.reset { DatabaseCleaner.clean_with(:truncation) }
  qa.check("refund recorded") { |params| Refund.exists?(order_id: params[:id]) }

  # Flags default to Flipper when it is loaded.
  # qa.flag { |name, on| Features.set(name, on) }

  qa.exclude_pages(%r{\A/admin/sidekiq})
end
```

A part you don't configure makes its hook answer `404`, which Talooner QA reads
as "not implemented".

## The hooks

| hook | request | answer |
|---|---|---|
| `GET /__qa/roles` | | `{"inventory": ["user_reduced", "admin"]}` |
| `GET /__qa/pages` | | `{"order": "/orders/:id"}`: named GET routes from the router |
| `GET /__qa/seeds` | | `{"seeds": ["order", "order:paid", "big_order"]}` |
| `POST /__qa/login` | `{"inventory": "admin"}` | `204`, session in `Set-Cookie` |
| `POST /__qa/seed` | `{"name": "order:paid"}` | `{"id": 42, "status": "paid", "param": "42"}` |
| `POST /__qa/reset` | | `204` |
| `POST /__qa/flag` | `{"name": "new_checkout", "on": true}` | `204` |
| `GET /__qa/check?name=refund+recorded&id=42` | | `{"ok": true}` |

A bad request (an unknown seed or check, a login without roles) answers `422`
with `{"error": "..."}`.

A seed answers the record's scalar attributes. Anything matching your app's
`filter_parameters`, and any key that looks like a secret (`password`, `token`,
`secret`, `digest`, …), is left out, never masked.

A check must return `true` or `false`; anything else is a `422`, never a pass.

### Shared data and parallel scenarios

Seed a realistic world once per preview, and let scenarios only read it. A
scenario that changes data should seed its own record from a factory, so
scenarios never depend on each other and can run in parallel without a reset in
between.

## Requirements

Ruby ≥ 3.4, Rails ≥ 7.2.

## License

Apache-2.0
