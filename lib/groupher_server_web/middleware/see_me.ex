# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule GroupherServerWeb.Middleware.SeeMe do
  @behaviour Absinthe.Middleware

  def call(resolution, _) do
    # IO.inspect("see me")
    # IO.inspect resolution.arguments, label: "see me"
    resolution
  end
end
