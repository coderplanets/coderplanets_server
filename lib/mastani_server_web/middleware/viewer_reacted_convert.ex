# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.ViewerReactedConvert do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function

  def call(%{value: nil} = resolution, _) do
    %{resolution | value: false}
  end

  def call(%{value: value} = resolution, _) do
    case List.first(value) do
      nil -> %{resolution | value: false}
      count -> %{resolution | value: true}
    end
  end

  def call(resolution, _), do: resolution
end
