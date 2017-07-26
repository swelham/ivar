use Mix.Config

config :ivar,
  adapter: Ivar.Testing.TestAdapter,
  http: [
    params: [
      {"q", "ivar"}
    ]
  ]
