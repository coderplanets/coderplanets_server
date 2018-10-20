# ---
# cut comments participators manually
#
# ---
defmodule MastaniServerWeb.Middleware.CutParticipators do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(%{value: value} = resolution, _) do
    # IO.inspect value |> Enum.slice(0, 5), label: "hello value --> "
    %{resolution | value: value |> Enum.slice(0, 5)}
  end

  # def call(%{value: []} = resolution, _) do
  #   %{resolution | value: 0}
  # end

  def call(resolution, _), do: resolution
end
