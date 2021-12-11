defmodule Helper.OAuth2.Github do
  use Tesla, only: [:get, :post]
  import Helper.Utils, only: [get_config: 2]

  # see Tesla intro: https://medium.com/@teamon/introducing-tesla-the-flexible-http-client-for-elixir-95b699656d88
  @timeout_limit 5000

  # @client_id get_config(:github_oauth, :client_id)
  # @client_secret get_config(:github_oauth, :client_secret)
  @redirect_uri get_config(:github_oauth, :redirect_uri)

  @endpoint_token "https://github.com/login/oauth/access_token"
  @endpoint_user "https://api.github.com/user"

  plug(Tesla.Middleware.Headers, [{"Accept", "application/json"}])

  plug(Tesla.Middleware.Retry, delay: 300, max_retries: 2)
  plug(Tesla.Middleware.Timeout, timeout: @timeout_limit)
  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.FormUrlencoded)

  def user_profile(code) do
    query = [
      code: code,
      # 不知道是不是 Bug, 如果把这个提出去会导致读取不到。。
      client_id: get_config(:github_oauth, :client_id),
      client_secret: get_config(:github_oauth, :client_secret),
      redirect_uri: @redirect_uri
    ]

    try do
      ret = post(@endpoint_token, %{}, query: query)

      case ret do
        {:ok, %Tesla.Env{body: %{"error" => error, "error_description" => description}}} ->
          {:error, "#{error}: #{description}"}

        {:ok, %Tesla.Env{status: 200, body: %{"access_token" => access_token}}} ->
          user_info(access_token)
      end
    rescue
      e ->
        e |> handle_tesla_error
    end
  end

  defp user_info(access_token) do
    query = [access_token: access_token]
    headers = [{"Authorization", "token #{access_token}"}]

    try do
      ret = get(@endpoint_user, query: query, headers: headers)

      case ret do
        {:ok, %Tesla.Env{status: 200, body: body}} ->
          body = body |> Map.merge(%{"access_token" => access_token})
          {:ok, body}

        {:ok, %Tesla.Env{status: 401, body: body}} ->
          {:error, "OAuth2 Github: " <> body["message"]}

        {:ok, %Tesla.Env{status: 403, body: body}} ->
          {:error, "OAuth2 Github: " <> body}

        _ ->
          {:error, "OAuth2 Github: unhandle error"}
      end
    rescue
      e ->
        e |> handle_tesla_error
    end
  end

  defp handle_tesla_error(error) do
    case error do
      %{reason: :timeout} -> {:error, "OAuth2 Github: timeout in #{@timeout_limit} msec"}
      %{reason: reason} -> {:error, "OAuth2 Github: #{reason}"}
      _ -> {:error, "unhandle error #{inspect(error)}"}
    end
  end
end
