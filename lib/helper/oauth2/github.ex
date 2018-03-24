defmodule Helper.OAuth2.Github do
  # use Tesla, only: ~w(get)a
  use Tesla, only: [:get]

  # see Tesla intro: https://medium.com/@teamon/introducing-tesla-the-flexible-http-client-for-elixir-95b699656d88
  # API usage: https://hexdocs.pm/tesla/readme.html

  # https://api.github.com/authorizations/3b4281c5e54ffd801f85/fba2f79cedb103aa147f72f15f07a8c238450377
  # @github_client_id "3b4281c5e54ffd801f85"
  # @user_token "fba2f79cedb103aa147f72f15f07a8c238450377"
  @timeout_limit 5000
  # @user_token ""
  plug(Tesla.Middleware.BaseUrl, "https://api.github.com")
  plug(Tesla.Middleware.Headers, %{"User-Agent" => "mastani server"})
  plug(Tesla.Middleware.Retry, delay: 200, max_retries: 2)
  plug(Tesla.Middleware.Timeout, timeout: @timeout_limit)
  # plug Tesla.Middleware.Tuples
  plug(Tesla.Middleware.JSON)

  def user_info(user_token) do
    try do
      case get("user", query: [access_token: user_token]) do
        %{status: 200, body: body} ->
          {:ok, body}

        %{status: 401, body: body} ->
          {:error, "OAuth2 Github: " <> body["message"]}

        %{status: 403, body: body} ->
          {:error, "OAuth2 Github: " <> body}

        error ->
          {:error, "OAuth2 Github: unhandle error"}
      end
    rescue
      e ->
        e |> handle_tesla_error
    end
  end

  defp handle_tesla_error(error) do
    IO.inspect(error, label: "error")

    case error do
      %{reason: :timeout} -> {:error, "OAuth2 Github: timeout in #{@timeout_limit} msec"}
      %{reason: reason} -> {:error, "OAuth2 Github: #{reason}"}
    end
  end
end
