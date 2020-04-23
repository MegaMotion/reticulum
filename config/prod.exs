use Mix.Config

# For production, we often load configuration from external
# sources, such as your system environment. For this reason,
# you won't find the :http configuration below, but set inside
# RetWeb.Endpoint.init/2 when load_from_system_env is
# true. Any dynamic configuration should be done there.
#
# Don't forget to configure the url host to something meaningful,
# Phoenix uses this information when generating URLs.
#
# Finally, we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the mix phx.digest task
# which you typically run after static files are built.
config :ret, RetWeb.Endpoint,
  https: [
    port: 4000,
    otp_app: :ret
  ],
  http: [
    port: 4001,
    otp_app: :ret
  ],
  url: [scheme: "https", host: "", port: 443],
  secondary_url: [scheme: "https", host: "", port: 443],
  static_url: [scheme: "https", host: "", port: 443],
  cors_proxy_url: [scheme: "https", host: "", port: 443],
  assets_url: [scheme: "https", host: "", port: 443],
  link_url: [scheme: "https", host: "", port: 443],
  imgproxy_url: [scheme: "http", host: "", port: 5000],
  pubsub: [name: Ret.PubSub, adapter: Phoenix.PubSub.PG2, pool_size: 4],
  server: true,
  root: "."

# Do not print debug messages in production
config :logger, level: :info

config :ret, Ret.Repo,
  username: "postgres",
  password: "postgres",
  database: "ret_production",
  hostname: "localhost",
  template: "template0",
  pool_size: 10

config :ret, Ret.SessionLockRepo,
  username: "postgres",
  password: "postgres",
  database: "ret_production",
  hostname: "localhost",
  template: "template0",
  pool_size: 10

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :ret, RetWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [:inet6,
#               port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :ret, RetWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :ret, RetWeb.Endpoint, server: true
#

# Finally import the config/prod.secret.exs
# which should be versioned separately.
import_config "prod.secret.exs"

# Filter out media search API params
config :phoenix, :filter_parameters, ["q", "filter", "cursor"]

# Disable prepared queries bc of pgbouncer
config :ret, Ret.Repo, adapter: Ecto.Adapters.Postgres, prepare: :unnamed

config :peerage, via: Ret.PeerageProvider

config :ret, page_auth: [username: "", password: "", realm: "Reticulum"]

config :ret, Ret.Scheduler,
  jobs: [
    # Send stats to StatsD every 5 seconds
    {{:extended, "*/5 * * * *"}, {Ret.StatsJob, :send_statsd_gauges, []}},

    # Flush stats to db every 5 minutes
    {{:cron, "*/5 * * * *"}, {Ret.StatsJob, :save_node_stats, []}},

    # Keep database warm when connected users
    {{:cron, "*/3 * * * *"}, {Ret.DbWarmerJob, :warm_db_if_has_ccu, []}},

    # Rotate TURN secrets if enabled
    {{:cron, "*/5 * * * *"}, {Ret.Coturn, :rotate_secrets, []}},

    # Various maintenence routines
    {{:cron, "0 10 * * *"}, {Ret.Storage, :vacuum, []}},
    {{:cron, "3 10 * * *"}, {Ret.Storage, :demote_inactive_owned_files, []}},
    {{:cron, "4 10 * * *"}, {Ret.LoginToken, :expire_stale, []}},
    {{:cron, "5 10 * * *"}, {Ret.Hub, :vacuum_entry_codes, []}},
    {{:cron, "6 10 * * *"}, {Ret.Hub, :vacuum_hosts, []}},
    {{:cron, "7 10 * * *"}, {Ret.CachedFile, :vacuum, []}}
  ]

config :ret, RetWeb.Plugs.HeaderAuthorization, header_name: "x-ret-admin-access-key"

config :ret, Ret.Mailer,
  adapter: Bamboo.SMTPAdapter,
  tls: :always,
  ssl: false,
  retries: 3

config :ret, Ret.Guardian, issuer: "ret", ttl: {12, :weeks}, allowed_drift: 60 * 1000

config :tzdata, :autoupdate, :disabled

config :sentry,
  environment_name: :prod,
  json_library: Poison,
  included_environments: [:prod],
  tags: %{
    env: "prod"
  }

config :ret, Ret.RoomAssigner, balancer_weights: [{600, 1}, {300, 50}, {0, 500}]

config :ret, Ret.Locking,
  lock_timeout_ms: 1000 * 60 * 15,
  session_lock_db: [
    username: "postgres",
    password: "postgres",
    database: "ret_production",
    hostname: "localhost"
  ]

config :ret, Ret.JanusLoadStatus, janus_port: 443

# Default stats job to off so for polycosm hosts the database can go idle
config :ret, Ret.StatsJob, node_stats_enabled: false, node_gauges_enabled: false

# Default repo check and page check to off so for polycosm hosts database + s3 hits can go idle
config :ret, RetWeb.HealthController, check_repo: false
