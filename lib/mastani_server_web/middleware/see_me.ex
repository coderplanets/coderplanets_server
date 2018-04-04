# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.SeeMe do
  @behaviour Absinthe.Middleware

  def call(res, _) do
    IO.inspect("see me")
    res
  end
end
