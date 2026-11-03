# frozen_string_literal: true

TaloonerQa::Engine.routes.draw do
  get "roles", to: "hooks#roles"
  get "pages", to: "hooks#pages"
  get "seeds", to: "hooks#seeds"
  post "login", to: "hooks#login"
  post "seed", to: "hooks#seed"
  post "reset", to: "hooks#reset"
  post "flag", to: "hooks#flag"
  get "check", to: "hooks#check"
end
