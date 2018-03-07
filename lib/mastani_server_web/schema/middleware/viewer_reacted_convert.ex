# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Schema.Middleware.ViewerReactedConvert do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function

  def call(res, _) do
    # IO.inspect res.value, label: 'ViewerReactedConvert'

    case List.first(res.value) do
      nil -> %{res | value: false}
      count -> %{res | value: true}
    end
  end
end
