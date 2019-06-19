# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule GroupherServerWeb.Middleware.PutCurrentUser do
  @behaviour Absinthe.Middleware

  def call(%{context: %{cur_user: cur_user}} = resolution, _) do
    arguments = resolution.arguments |> Map.merge(%{cur_user: cur_user})

    %{resolution | arguments: arguments}
  end

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(resolution, _) do
    resolution
  end
end
