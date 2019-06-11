# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule GroupherServerWeb.Middleware.PutRootSource do
  @behaviour Absinthe.Middleware

  # def call(%{source: %{id: id}} = resolution, _) do
  # arguments = resolution.arguments |> Map.merge(%{root_source_id: id})

  # %{resolution | arguments: arguments}
  # end

  def call(%{source: %{id: id}} = resolution, _) do
    arguments = resolution.arguments |> Map.merge(%{jj: id})

    %{resolution | arguments: arguments}
    # resolution
  end

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(resolution, _), do: resolution
end
