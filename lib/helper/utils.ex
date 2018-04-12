defmodule Helper.Utils do
  import Ecto.Query, warn: false

  def get_config(section, key, app \\ :mastani_server) do
    Application.get_env(app, section) |> Keyword.get(key)
  end

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

  def map_key_stringify(%{__struct__: _} = map) when is_map(map) do
    map = Map.from_struct(map)
    map |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, to_string(key), val) end)
  end

  def map_key_stringify(map) when is_map(map) do
    map |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, to_string(key), val) end)
  end

  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  def tobe_integer(val) do
    if is_integer(val),
      do: val,
      else: val |> String.to_integer()
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right) do
    right
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
