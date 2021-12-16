# ---
# Absinthe.Middleware behaviour
# ---
defmodule GroupherServerWeb.Middleware.Debug do
  @moduledoc """
  authorize gateway, mainly for login check
  """

  @behaviour Absinthe.Middleware

  import Helper.Utils, only: [handle_absinthe_error: 3]
  import Helper.ErrorCode

  def call(%{context: %{cur_user: _}} = resolution, _info) do
    IO.inspect(resolution.value.original_community.viewer_has_subscribed, label: "## resolution")
    resolution
  end

  def call(resolution, _) do
    resolution
    |> handle_absinthe_error("Authorize: need login", ecode(:account_login))
  end
end
