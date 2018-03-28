defmodule MastaniServerWeb.Middleware.GithubUser do
  @behaviour Absinthe.Middleware

  import Helper.Utils, only: [handle_absinthe_error: 2]
  alias Helper.OAuth2.Github

  def call(%{arguments: %{code: code}} = resolution, _) do
    # IO.inspect(access_token, label: "GithubUser middleware token")

    case Github.user_profile(code) do
      {:ok, user} ->
        # IO.inspect user,label: "get ok"
        arguments = resolution.arguments |> Map.merge(%{github_user: user})
        %{resolution | arguments: arguments}

      {:error, err_msg} ->
        resolution
        |> handle_absinthe_error(err_msg)
    end
  end
end
