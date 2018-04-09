# ---
# Absinthe.Middleware behaviour
# ---
defmodule MastaniServerWeb.Middleware.Authorize do
  @behaviour Absinthe.Middleware
  import Helper.Utils, only: [handle_absinthe_error: 2]

  def call(%{context: %{cur_user: _}} = resolution, _info) do
    resolution
  end

  def call(resolution, _) do
    resolution
    |> handle_absinthe_error("Authorize: need login")
  end
end
