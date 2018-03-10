# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.PutCurrentUser do
  @behaviour Absinthe.Middleware

  def call(resolution, _) do
    case Map.has_key?(resolution.context, :current_user) do
      true ->
        %{
          resolution
          | arguments:
              Map.merge(resolution.arguments, %{current_user: resolution.context.current_user})
        }

      _ ->
        resolution
    end

    # %{resolution | arguments: Map.merge(resolution.arguments, %{current_user: resolution.context.current_user})}
  end
end
