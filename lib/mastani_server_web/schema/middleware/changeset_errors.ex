# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Schema.Middleware.ChangesetErrors do
  @behaviour Absinthe.Middleware

  def call(res, _) do
    with %{errors: [%Ecto.Changeset{} = changeset]} <- res do
      # IO.inspect transform_errors(changeset), label: 'changeset call'
      %{res | value: [], errors: transform_errors(changeset)}
    end
  end

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
