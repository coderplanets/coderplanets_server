# ---
# Absinthe.Middleware behaviour
# ---
defmodule MastaniServerWeb.Middleware.Authorize do
  @behaviour Absinthe.Middleware
  import Helper.Utils, only: [handle_absinthe_error: 3]
  import Helper.ErrorCode

  def call(%{context: %{cur_user: _}} = resolution, _info), do: resolution

  def call(resolution, _) do
    resolution
    |> handle_absinthe_error("Authorize: need login", ecode(:account_login))
  end
end
