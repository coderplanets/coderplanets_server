# ---
# Absinthe.Middleware behaviour
# TODO
# ---
defmodule MastaniServerWeb.Middleware.Authorize do
  @behaviour Absinthe.Middleware

  def call(resolution, role) do
    # IO.inspect(resolution.context, label: 'Authorize')

    with %{current_user: current_user} <- resolution.context,
         true <- valid_role?(current_user, role) do
      resolution
    else
      _ ->
        # IO.inspect(resolution.context, label: 'context else')
        error_msg =
          case Map.has_key?(resolution.context, :current_user) do
            true -> "Authorize: unauthorized role"
            _ -> "Authorize: need login"
          end

        resolution
        |> Absinthe.Resolution.put_result({:error, error_msg})
    end
  end

  # defp valid_role?(%{}, :any), do: true
  defp valid_role?(_, :login), do: true
  defp valid_role?(%{role: role}, role), do: true
  defp valid_role?(_, _), do: false
end
