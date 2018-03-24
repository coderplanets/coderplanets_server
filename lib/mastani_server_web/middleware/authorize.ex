# ---
# Absinthe.Middleware behaviour
# ---
defmodule MastaniServerWeb.Middleware.Authorize do
  @behaviour Absinthe.Middleware
  import Helper.Utils, only: [handle_absinthe_error: 2]

  def call(%{context: %{current_user: current_user}} = resolution, role) do
    case valid_role?(current_user, role) do
      true -> resolution
      _ -> handle_error(resolution)
    end
  end

  def call(resolution, _) do
    handle_error(resolution)
  end

  # defp valid_role?(%{}, :any), do: true
  defp valid_role?(_, :login), do: true
  defp valid_role?(%{role: role}, role), do: true
  defp valid_role?(_, _), do: false

  defp handle_error(%{context: %{current_user: _}} = resolution) do
    resolution
    |> handle_absinthe_error("Authorize: unauthorized role")
  end

  defp handle_error(resolution) do
    resolution
    |> handle_absinthe_error("Authorize: need login")
  end
end
