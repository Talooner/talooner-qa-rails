# frozen_string_literal: true

RSpec.describe "/__qa hooks", type: :request do
  describe "the token" do
    it "refuses a call without the right token" do
      hook(:get, "pages", token: "wrong")
      expect(response).to have_http_status(:unauthorized)
    end

    it "answers 404 to everything when no token is set, as if nothing were mounted" do
      ENV.delete(TaloonerQa::TOKEN_VARIABLE)
      hook(:get, "pages", token: "")
      expect(response).to have_http_status(:not_found)
    end

    it "is never enabled in production unless asked for by name" do
      allow(Rails.env).to receive(:production?).and_return(true)
      expect(TaloonerQa.enabled?).to be(false)
      ENV[TaloonerQa::ALLOW_PRODUCTION_VARIABLE] = "1"
      expect(TaloonerQa.enabled?).to be(true)
    end
  end

  describe "GET roles" do
    it "serves the app's roles" do
      TaloonerQa.configure { it.roles { { inventory: %w[user_reduced admin] } } }
      hook(:get, "roles")
      expect(json).to eq("inventory" => %w[user_reduced admin])
    end

    it "is 404 when not configured, so talooner-qa falls back to files" do
      hook(:get, "roles")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET pages" do
    it "lists named GET routes, without the format, the hooks or Rails' own routes" do
      hook(:get, "pages")
      expect(json).to eq("order" => "/orders/:id", "orders" => "/orders", "admin_reports" => "/admin/reports")
    end

    it "leaves out what the app excludes" do
      TaloonerQa.configure { it.exclude_pages(%r{\A/admin/}) }
      hook(:get, "pages")
      expect(json.keys).to contain_exactly("order", "orders")
    end
  end

  describe "seeds" do
    it "lists factories, their traits, named seeds and sources" do
      TaloonerQa.configure do |qa|
        qa.seed("big_order") { Order.create!(number: "B-1", total: 999) }
        qa.seeds_from_factory_bot
        qa.seeds(names: -> { ["inventory.items.drill"] }, seed: ->(_name) { { id: 7 } })
      end
      hook(:get, "seeds")
      expect(json).to eq("seeds" => ["big_order", "order", "order:paid", "inventory.items.drill"])
    end

    it "is 404 when nothing is configured" do
      hook(:get, "seeds")
      expect(response).to have_http_status(:not_found)
    end

    it "creates from a factory and trait, returning scalars and never secrets" do
      TaloonerQa.configure(&:seeds_from_factory_bot)
      hook(:post, "seed", { name: "order:paid" })
      order = Order.last
      expect(order.status).to eq("paid")
      expect(json).to include("id" => order.id, "number" => "A-7", "status" => "paid", "total" => "19.5", "param" => order.id.to_s)
      expect(json).not_to have_key("api_token")
    end

    it "adds the app's attributes to every factory create" do
      TaloonerQa.configure { |qa| qa.seeds_from_factory_bot(attributes: ->(_factory) { { number: "ACC-1" } }) }
      hook(:post, "seed", { name: "order" })
      expect(json["number"]).to eq("ACC-1")
    end

    it "lets a named seed win over a factory of the same name" do
      TaloonerQa.configure do |qa|
        qa.seeds_from_factory_bot
        qa.seed("order") { { id: 1, origin: "named" } }
      end
      hook(:post, "seed", { name: "order" })
      expect(json).to eq("id" => 1, "origin" => "named")
    end

    it "serves a seeded world's records by key" do
      world = { "inventory.items.drill" => { id: 7, name: "Drill" } }
      TaloonerQa.configure { |qa| qa.seeds(names: -> { world.keys }, seed: ->(name) { world.fetch(name) }) }
      hook(:post, "seed", { name: "inventory.items.drill" })
      expect(json).to eq("id" => 7, "name" => "Drill")
    end

    it "drops what the app filters from its logs" do
      TaloonerQa.configure { |qa| qa.seed("user") { User.create!(email: "qa@example.com", inventory_role: "admin") } }
      hook(:post, "seed", { name: "user" })
      expect(json).to include("inventory_role" => "admin")
      expect(json).not_to have_key("email")
    end

    it "names an unknown seed" do
      TaloonerQa.configure(&:seeds_from_factory_bot)
      hook(:post, "seed", { name: "invoice" })
      expect(response).to have_http_status(422)
      expect(json["error"]).to eq('no seed named "invoice"; GET /__qa/seeds lists them')
    end
  end

  describe "POST login" do
    it "signs in a user with exactly the given roles" do
      signed_in = nil
      TaloonerQa.configure do |qa|
        qa.user_for { |roles| User.create!(email: "qa+#{roles.values.join}@example.com", inventory_role: roles["inventory"]) }
        qa.sign_in do |controller, user|
          signed_in = user
          controller.session[:user_id] = user.id
        end
      end
      hook(:post, "login", { inventory: "user_reduced" })
      expect(response).to have_http_status(:no_content)
      expect(signed_in.inventory_role).to eq("user_reduced")
      expect(response.headers["Set-Cookie"]).to be_present
    end

    it "refuses a login without roles: a guest does not log in" do
      TaloonerQa.configure { |qa| qa.user_for { User.new } }
      hook(:post, "login", {})
      expect(response).to have_http_status(422)
      expect(json["error"]).to eq("login needs at least one {area: role}; a guest does not log in")
    end

    it "says how to sign in when Devise is not loaded" do
      TaloonerQa.configure { |qa| qa.user_for { User.create! } }
      hook(:post, "login", { inventory: "admin" })
      expect(response).to have_http_status(422)
      expect(json["error"]).to start_with("no sign_in configured and Devise is not loaded")
    end
  end

  describe "POST reset and flag" do
    it "runs the app's reset" do
      called = false
      TaloonerQa.configure { |qa| qa.reset { called = true } }
      hook(:post, "reset")
      expect(response).to have_http_status(:no_content)
      expect(called).to be(true)
    end

    it "sets a flag through the app's block" do
      flags = {}
      TaloonerQa.configure { |qa| qa.flag { |name, on| flags[name] = on } }
      hook(:post, "flag", { name: "new_checkout", on: false })
      expect(flags).to eq("new_checkout" => false)
    end

    it "uses Flipper when it is loaded" do
      flipper = Module.new do
        def self.enabled = (@enabled ||= [])
        def self.enable(name) = enabled << name
      end
      stub_const("Flipper", flipper)
      hook(:post, "flag", { name: "new_checkout", on: true })
      expect(flipper.enabled).to eq(["new_checkout"])
    end
  end

  describe "GET check" do
    before do
      TaloonerQa.configure do |qa|
        qa.check("order paid") { |params| Order.exists?(id: params[:id], status: "paid") }
        qa.check("sloppy") { |_params| Order.first }
      end
    end

    it "answers an explicit ok" do
      order = Order.create!(status: "paid")
      hook(:get, "check?name=order+paid&id=#{order.id}")
      expect(json).to eq("ok" => true)
      hook(:get, "check?name=order+paid&id=0")
      expect(json).to eq("ok" => false)
    end

    it "refuses an answer that is not true or false" do
      hook(:get, "check?name=sloppy")
      expect(response).to have_http_status(422)
      expect(json["error"]).to eq('check "sloppy" returned nil, want true or false')
    end

    it "names an unknown check" do
      hook(:get, "check?name=mail+sent")
      expect(json["error"]).to eq('no check named "mail sent"')
    end
  end
end
