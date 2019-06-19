defmodule Helper.OAuth2.Github do
  use Tesla, only: [:get, :post]
  import Helper.Utils, only: [get_config: 2]

  # see Tesla intro: https://medium.com/@teamon/introducing-tesla-the-flexible-http-client-for-elixir-95b699656d88
  @timeout_limit 5000
  # @client_id get_config(:github_oauth, :client_id)
  # @client_secret get_config(:github_oauth, :client_secret)
  @redirect_uri "https://www.coderplanets.com/oauth"

  # wired only this style works
  plug(Tesla.Middleware.BaseUrl, "https://github.com/login/oauth")
  # plug(Tesla.Middleware.BaseUrl, "https://www.github.com/login/oauth")
  # plug(Tesla.Middleware.BaseUrl, "https://api.github.com/login/oauth")
  plug(Tesla.Middleware.Headers, %{
    "User-Agent" => "groupher server"
    # "Accept" => "application/json"
    # "Accept" => "application/json;application/vnd.github.jean-grey-preview+json"
  })

  plug(Tesla.Middleware.Retry, delay: 200, max_retries: 2)
  plug(Tesla.Middleware.Timeout, timeout: @timeout_limit)
  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.FormUrlencoded)

  def user_profile(code) do
    # body = "client_id=#{@client_id}&client_secret=#{@client_secret}&code=#{code}&redirect_uri=#{@redirect_uri}"
    # post("access_token?#{body}",%{})
    headers = %{"Accept" => "application/json"}

    query = [
      code: code,
      client_id: get_config(:github_oauth, :client_id),
      client_secret: get_config(:github_oauth, :client_secret),
      redirect_uri: @redirect_uri
    ]

    try do
      case post("/access_token", %{}, query: query, headers: headers) do
        %{status: 200, body: %{"error" => error, "error_description" => description}} ->
          {:error, "#{error}: #{description}"}

        %{status: 200, body: %{"access_token" => access_token, "token_type" => "bearer"}} ->
          user_info(access_token)
      end
    rescue
      e ->
        e |> handle_tesla_error
    end
  end

  def user_info(access_token) do
    url = "https://api.github.com/user"
    # this special header is too get node_id
    # see: https://developer.github.com/v3/

    headers = %{"Accept" => "application/vnd.github.jean-grey-preview+json"}
    query = [access_token: access_token]

    try do
      case get(url, query: query, headers: headers) do
        %{status: 200, body: body} ->
          body = body |> Map.merge(%{"access_token" => access_token})
          {:ok, body}

        %{status: 401, body: body} ->
          {:error, "OAuth2 Github: " <> body["message"]}

        %{status: 403, body: body} ->
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
