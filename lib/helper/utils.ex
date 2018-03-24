defmodule Helper.Utils do
  import Ecto.Query, warn: false

  @doc """
  handle General {:ok, ..} or {:error, ..} return
  """

  def done(nil, :boolean), do: {:ok, false}
  def done(_, :boolean), do: {:ok, true}
  def done(nil, err_msg), do: {:error, err_msg}

  def done(nil, queryable, id), do: {:error, not_found_formater(queryable, id)}
  def done(result, _, _), do: {:ok, result}

  def done(nil), do: {:error, "record not found."}
  def done(result), do: {:ok, result}

  def handle_absinthe_error(resolution, err_msg) when is_list(err_msg) do
    # %{resolution | value: [], errors: transform_errors(changeset)}
    resolution
    |> Absinthe.Resolution.put_result({:error, err_msg})
  end

  def handle_absinthe_error(resolution, err_msg) when is_binary(err_msg) do
    resolution
    |> Absinthe.Resolution.put_result({:error, err_msg})
  end

  def map_key_stringify(map) when is_map(map) do
    map |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, to_string(key), val) end)
  end

  # graphql treat id as string
  defp not_found_formater(queryable, id) when is_integer(id) or is_binary(id) do
    modal_sortname = queryable |> to_string |> String.split(".") |> List.last()
    "#{modal_sortname}(#{id}) not found"
  end

  defp not_found_formater(queryable, clauses) do
    modal_sortname = queryable |> to_string |> String.split(".") |> List.last()

    detail =
      clauses
      |> Enum.into(%{})
      |> Map.values()
      |> List.first()
      |> to_string

    "#{modal_sortname}(#{detail}) not found"
  end
end
