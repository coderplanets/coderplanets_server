# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Schema.Middleware.PutCurrentUser do
  @behaviour Absinthe.Middleware

  def call(res, _) do
    %{res | arguments: Map.merge(res.arguments, %{current_user: res.context.current_user})}
  end
end
