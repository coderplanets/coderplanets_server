# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule GroupherServerWeb.Middleware.ConvertToInt do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(%{value: [value]} = resolution, _) do
    %{resolution | value: value}
  end

  def call(%{value: []} = resolution, _) do
    %{resolution | value: 0}
  end

  def call(resolution, _), do: resolution
end
