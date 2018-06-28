# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.ChangesetErrors do
  @behaviour Absinthe.Middleware
  import Helper.Utils, only: [handle_absinthe_error: 3]
  import Helper.ErrorCode

  alias MastaniServerWeb.Gettext, as: Translator

  def call(%{errors: [%Ecto.Changeset{} = changeset]} = resolution, _) do
    # IO.inspect changeset, label: "Changeset error"
    # IO.inspect transform_errors(changeset), label: "transform_errors"
    resolution
    |> handle_absinthe_error(transform_errors(changeset), ecode(:changeset))
  end

  def call(resolution, _), do: resolution

  defp transform_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&format_error/1)
    |> Enum.map(fn {key, err_msg_list} ->
      err_msg = err_msg_list |> List.first()

      cond do
        Map.has_key?(err_msg, :count) ->
          %{
            key: Translator |> Gettext.dgettext("fields", "#{key}"),
            message: Translator |> Gettext.dgettext("errors", err_msg.raw, count: err_msg.count)
          }

        true ->
          %{
            key: Translator |> Gettext.dgettext("fields", "#{key}"),
            message: Translator |> Gettext.dgettext("errors", err_msg.msg)
          }
      end
    end)
  end

  defp format_error({msg, opts}) do
    err_string =
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)

    # TODO handle: number type
    cond do
      String.contains?(msg, "%{count}") ->
        %{
          msg: err_string,
          count: Keyword.get(opts, :count),
          raw: msg
        }

      true ->
        %{
          msg: err_string
        }
    end
  end
end
