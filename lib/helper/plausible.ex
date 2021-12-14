defmodule Helper.Plausible do
  @moduledoc """
  find city info by ip
  refer: https://lbs.amap.com/api/webservice/guide/api/ipconfig/?sug_index=0
  """
  use Tesla, only: [:get]
  import Helper.Utils, only: [get_config: 2]

  alias Helper.Cache

  @endpoint "https://plausible.io"
  @realtime_visitors_query "/api/v1/stats/realtime/visitors"
  @timeout_limit 4000

  @site_id "coderplanets.com"
  # @token get_config(:plausible, :token)

  @cache_pool :online_status

  plug(Tesla.Middleware.BaseUrl, @endpoint)
  # plug(Tesla.Middleware.Headers, [{"Authorization", "Bearer #{@token}"}])
  plug(Tesla.Middleware.Retry, delay: 200, max_retries: 2)
  plug(Tesla.Middleware.Timeout, timeout: @timeout_limit)
  plug(Tesla.Middleware.JSON)

  defp get_token(), do: get_config(:plausible, :token)

  def realtime_visitors() do
    query = [site_id: @site_id]
    path = "#{@realtime_visitors_query}"
    # NOTICE: DO NOT use Tesla.get, otherwise the middleware will not woking
    # see https://github.com/teamon/tesla/issues/88
    # with true <- Mix.env() !== :test do
    with {:ok, %{body: body}} <-
           get(path, query: query, headers: [{"Authorization", "Bearer #{get_token()}"}]) do
      case is_number(body) do
        true ->
          Cache.put(@cache_pool, :realtime_visitors, body)
          {:ok, Enum.max([body, 1])}

        false ->
          {:ok, 1}
      end
    else
      _ ->
        Cache.put(@cache_pool, :realtime_visitors, 1)
        {:ok, 1}
    end
  end
end
