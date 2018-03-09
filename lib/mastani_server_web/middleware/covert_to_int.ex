# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.ConvertToInt do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function

  def call(res, _) do
    # with %{errors: errors} <- res do
    case List.first(res.value) do
      nil -> %{res | value: 0}
      count -> %{res | value: count}
    end
  end
end
