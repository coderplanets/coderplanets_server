defmodule Helper.ErrorHandler do
  alias MastaniServerWeb.Gettext, as: Translator

  def not_found_formater(queryable, id) when is_integer(id) or is_binary(id) do
    modal = queryable |> to_string |> String.split(".") |> List.last()

    Translator |> Gettext.dgettext("404", "#{modal}(%{id}) not found", id: id)
  end

  def not_found_formater(queryable, clauses) do
    modal = queryable |> to_string |> String.split(".") |> List.last()

    detail =
      clauses
      |> Enum.into(%{})
      |> Map.values()
      |> List.first()
      |> to_string

    Translator |> Gettext.dgettext("404", "#{modal}(%{name}) not found", name: detail)
  end
end
