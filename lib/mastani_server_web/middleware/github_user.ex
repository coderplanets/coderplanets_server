defmodule MastaniServerWeb.Middleware.GithubUser do
  @behaviour Absinthe.Middleware

  import Helper.Utils, only: [handle_absinthe_error: 2]
  alias Helper.OAuth2.Github

  def call(%{arguments: %{code: code}} = resolution, _) do
    IO.inspect(code, label: "GithubUser middleware code")

    case Github.user_profile(code) do
      {:ok, user} ->
        IO.inspect(user, label: "user_profile")
        arguments = resolution.arguments |> Map.merge(%{github_user: user})
        %{resolution | arguments: arguments}

      {:error, err_msg} ->
        IO.inspect(err_msg, label: "user_profile error")

        resolution
        |> handle_absinthe_error(err_msg)
    end
  end
end
