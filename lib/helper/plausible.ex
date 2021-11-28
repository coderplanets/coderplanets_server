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
  @service_key get_config(:plausible, :token)

  @cache_pool :online_status

  plug(Tesla.Middleware.BaseUrl, @endpoint)
  plug(Tesla.Middleware.Headers, [{"Authorization", "Bearer #{@service_key}"}])
  plug(Tesla.Middleware.Retry, delay: 200, max_retries: 2)
  plug(Tesla.Middleware.Timeout, timeout: @timeout_limit)
  plug(Tesla.Middleware.JSON)

  def realtime_visitors() do
    query = [site_id: @site_id]
    path = "#{@realtime_visitors_query}"
    # NOTICE: DO NOT use Tesla.get, otherwise the middleware will not woking
    # see https://github.com/teamon/tesla/issues/88
    # with true <- Mix.env() !== :test do
    with {:ok, result} <- get(path, query: query),
         Cache.put(@cache_pool, :realtime_visitors, result.body) do
      # cache_get = Cache.get(@cache_pool, :realtime_visitors)
      {:ok, result.body}
    else
      error ->
        IO.inspect(error, label: "got error")
    end
  end
end
