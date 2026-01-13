import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :dead_simple_cms, DeadSimpleCms.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "dead_simple_cms_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dead_simple_cms, DeadSimpleCmsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "rzq+rQWk7mELzarAQA9sCYqEUNr0cT+9dPVZED5IaCU605+cWrAAUTXEeUMe43Zb",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix, sort_verified_routes_query_params: true

# enable full app for running tests
config :dead_simple_cms, start_app: true
