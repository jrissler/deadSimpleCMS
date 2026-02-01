# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :dead_simple_cms,
  ecto_repos: [DeadSimpleCms.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true],
  repo: DeadSimpleCms.Repo,
  s3: [
    enabled?: true,
    bucket: System.get_env("DSCMS_S3_BUCKET"),
    region: System.get_env("DSCMS_S3_REGION"),
    # optional CDN base; if nil, use https://<bucket>.s3.amazonaws.com/<key>
    public_base_url: System.get_env("DSCMS_S3_PUBLIC_BASE_URL"),
    prefix: "dead_simple_cms"
  ],
  endpoint: DeadSimpleCmsWeb.Endpoint

# Configure the endpoint
config :dead_simple_cms, DeadSimpleCmsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: DeadSimpleCmsWeb.ErrorHTML, json: DeadSimpleCmsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DeadSimpleCms.PubSub,
  live_view: [signing_salt: "2avLr2Jr"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  installer: [
    args: ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  installer: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
