defmodule Helper.RadarSearch do
  @moduledoc """
  find city info by ip
  refer: https://lbs.amap.com/api/webservice/guide/api/ipconfig/?sug_index=0
  """
  use Tesla, only: [:get]
  import Helper.Utils, only: [get_config: 2]

  @endpoint "https://restapi.amap.com/v3/ip"
  @ip_service_key get_config(:radar_search, :ip_service)
  @timeout_limit 5000

  # plug(Tesla.Middleware.BaseUrl, "https://restapi.amap.com/v3/ip")
  plug(Tesla.Middleware.Retry, delay: 200, max_retries: 2)
  plug(Tesla.Middleware.Timeout, timeout: @timeout_limit)
  plug(Tesla.Middleware.JSON)

  @doc """
  this is only match fail situation in test
  """
  def locate_city(ip \\ "14.196.0.0")

  def locate_city(:fake_ip) do
    {:error, "not found"}
  end

  def locate_city(:localhost) do
    {:error, "localhost"}
  end

  # http://ip.yqie.com/search.aspx?searchword=%E6%88%90%E9%83%BD%E5%B8%82
  def locate_city(ip) do
    query = [ip: ip, key: @ip_service_key]
    IO.inspect(ip, label: "locate_city ip")
    IO.inspect(@ip_service_key, label: "@ip_service_key")

    with true <- Mix.env() !== :test do
      case get(@endpoint, query: query) do
        %{status: 200, body: %{"city" => city}} ->
          IO.inspect(city, label: "get city")
          handle_result({:ok, city})

        _error ->
          {:error, "error"}
      end
    else
      _ ->
        # NOTE: this only for test usage
        # error is ignored, just check next time
        {:ok, "成都"}
    end
  end

  # not valid io, just ignore it
  def locate_city(_ip), do: {:error, "invalid ip"}

  defp handle_result({:ok, result}) do
    case result do
      [] -> {:error, "not found"}
      _ -> cut_tail({:ok, result})
    end
  end

  defp cut_tail({:ok, result}) do
    case String.last(result) == "市" do
      true -> {:ok, String.trim_trailing(result, "市")}
      false -> {:ok, result}
    end
  end
end
