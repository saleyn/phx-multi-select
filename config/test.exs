import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :multi_select, MultiSelectExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "V8pSbQegn1RnSXgGAoPw6U8wTfsEOPKG2hnRUim855lCBhSETPrTp2EQKs2F3PHF",
  server: false

# In test we don't send emails.
config :multi_select, MultiSelectExample.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
