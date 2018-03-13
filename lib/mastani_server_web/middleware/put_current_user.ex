# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.PutCurrentUser do
  @behaviour Absinthe.Middleware

  def call(%{context: %{current_user: current_user}} = resolution, _) do
    arguments =
      resolution.arguments |> Map.merge(%{current_user: resolution.context.current_user})

    %{resolution | arguments: arguments}
  end

  def call(resolution, _), do: resolution
end
