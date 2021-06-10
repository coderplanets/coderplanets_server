defmodule Helper.HTML do
  @moduledoc """
  escape unsafe inputs, especially for the markdown contents
  """

  import Ecto.Changeset
  # alias Phoenix.HTML

  def safe_string(%Ecto.Changeset{valid?: true, changes: changes} = changeset, field) do
    case Map.has_key?(changes, field) do
      true -> changeset |> put_change(field, escape_to_safe_string(changes[field]))
      _ -> changeset
    end
  end

  def safe_string(%Ecto.Changeset{} = changeset, _field), do: changeset

  # def safe_string(%Ecto.Changeset{} = changeset, field) do
  # case changeset do
  # %Ecto.Changeset{valid?: true, changes: changes} ->
  # changeset
  # |> put_change(field, escape_to_safe_string(changes[field]))

  # _ ->
  # changeset
  # end
  # end

  # defp escape_to_safe_string(v), do: v |> HTML.html_escape() |> HTML.safe_to_string()
  defp escape_to_safe_string(v), do: v

  # defp escape_to_safe_string(v), do: v |> HTML.javascript_escape # HTML.html_escape() |> HTML.safe_to_string()
end
