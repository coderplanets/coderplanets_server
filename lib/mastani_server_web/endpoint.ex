defmodule MastaniServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :mastani_server

  socket("/socket", MastaniServerWeb.UserSocket)

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # plug(:inspect_conn)

  plug(
    Corsica,
    # log: [rejected: :error],
    log: [rejected: :debug],
    origins: [
      "http://localhost:3000",
      "http://localhost:3001",
      ~r{^https://(.*\.?)coderplanets\.com$}
    ],
    # origins: "*",
    allow_headers: [
      "authorization",
      "content-type",
      "special",
      "accept",
      "origin",
      "x-requested-with"
    ],
    allow_credentials: true,
    max_age: 600
  )

  plug(MastaniServerWeb.Router)

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port =
        System.get_env("SERVE_PORT") || raise "expected the PORT environment variable to be set"

      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end

  #  defp inspect_conn(conn, _), do: IO.inspect(conn)
end
