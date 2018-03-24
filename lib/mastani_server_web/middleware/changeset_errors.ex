# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.ChangesetErrors do
  @behaviour Absinthe.Middleware
  import Helper.Utils, only: [handle_absinthe_error: 2]

  def call(%{errors: [%Ecto.Changeset{} = changeset]} = resolution, _) do
    resolution
    |> handle_absinthe_error(transform_errors(changeset))
  end

  def call(resolution, _), do: resolution

  defp transform_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&format_error/1)
    |> Enum.map(fn {key, value} ->
      %{key: key, message: value}
    end)
  end

  defp format_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
