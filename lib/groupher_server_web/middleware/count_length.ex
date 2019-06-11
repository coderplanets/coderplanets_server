# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule GroupherServerWeb.Middleware.CountLength do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(%{value: []} = resolution, _) do
    %{resolution | value: 0}
  end

  def call(%{value: value} = resolution, _) when is_list(value) do
    %{resolution | value: length(value)}
  end

  def call(resolution, _), do: resolution
end
