defmodule Helper.RemoteIP do
  @moduledoc """
  parse remote ip in rep_headers -> x-forwarded-for
  """

  def parse([]) do
    {:error, "NOT_FOUND"}
  end

  # remote ip is the fisrt ip in the proxy_ips chain
  def parse([proxy_ips]) do
    client_ip = proxy_ips |> String.split(",") |> List.first()

    case client_ip not in slb_ips do
      true ->
        {:ok, client_ip}

      false ->
        {:error, "skip"}
    end
  end

  def parse(_) do
    {:error, "NOT_FOUND"}
  end

  defp slb_ips do
    # ecs / slbs ips
    ["47.100.162.182"]
  end
end
