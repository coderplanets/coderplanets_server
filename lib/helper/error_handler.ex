defmodule Helper.ErrorHandler do
  @moduledoc """
  This module defines some helper function used by
  handle/format changset errors
  """
  alias GroupherServerWeb.Gettext, as: Translator

  def not_found_formater(queryable, id) when is_integer(id) or is_binary(id) do
    model = queryable |> to_string |> String.split(".") |> List.last()

    Translator |> Gettext.dgettext("404", "#{model}(%{id}) not found", id: id)
  end

  def not_found_formater(queryable, clauses) do
    model = queryable |> to_string |> String.split(".") |> List.last()

    detail =
      clauses
      |> Enum.into(%{})
      |> Map.values()
      |> List.first()
      |> to_string

    Translator |> Gettext.dgettext("404", "#{model}(%{name}) not found", name: detail)
  end
end
