defmodule Helper.RemoteIP do
  @moduledoc """
  parse remote ip in rep_headers -> x-forwarded-for
  """

  # remote ip is the fisrt ip in the proxy_ips chain
  def parse([proxy_ips, _]) do
    client_ip = proxy_ips |> String.split(",") |> List.first()

    {:ok, client_ip}
  end

  def parse(_) do
    {:error, "NOT_FOUND"}
  end
end
