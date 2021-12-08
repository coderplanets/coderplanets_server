defmodule GroupherServerWeb.Middleware.GithubUser do
  @moduledoc """
  handle github oauth login
  """
  @behaviour Absinthe.Middleware

  import Helper.Utils, only: [handle_absinthe_error: 2]
  alias Helper.OAuth2.Github

  def call(%{arguments: %{code: code}} = resolution, _) do
    case Github.user_profile(code) do
      {:ok, user} ->
        arguments = resolution.arguments |> Map.merge(%{github_user: user})
        %{resolution | arguments: arguments}

      {:error, err_msg} ->
        resolution
        |> handle_absinthe_error(err_msg)
    end
  end
end
