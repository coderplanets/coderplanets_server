defmodule Helper.Utils.Map do
  @moduledoc """
  utils functions for map structure
  """
  @doc """
  map atom value to upcase string

  e.g:
  %{hello: :world} # -> %{hello: "WORLD"}
  """
  def atom_values_to_upcase(map) when is_map(map) do
    map
    |> Enum.reduce(%{}, fn {key, val}, acc ->
      case val !== true and val !== false and not is_nil(val) and is_atom(val) do
        true -> Map.put(acc, key, val |> to_string |> String.upcase())
        false -> Map.put(acc, key, val)
      end
    end)
  end

  def atom_values_to_upcase(value), do: value

  def map_key_stringify(%{__struct__: _} = map) when is_map(map) do
    map = Map.from_struct(map)
    map |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, to_string(key), val) end)
  end

  def map_key_stringify(map) when is_map(map) do
    map |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, to_string(key), val) end)
  end

  @doc """
  see https://stackoverflow.com/a/61559842/4050784
  adjust it for map keys from atom to string
  """
  def keys_to_atoms(map) when is_map(map) do
    Map.new(map, &reduce_keys_to_atoms/1)
  end

  def keys_to_atoms(string) when is_binary(string), do: string

  defp reduce_keys_to_atoms({key, val}) when is_map(val),
    # do: {String.to_existing_atom(key), keys_to_atoms(val)}
    do: {String.to_atom(key), keys_to_atoms(val)}

  defp reduce_keys_to_atoms({key, val}) when is_list(val),
    do: {String.to_atom(key), Enum.map(val, &keys_to_atoms(&1))}

  defp reduce_keys_to_atoms({key, val}), do: {String.to_atom(key), val}

  @doc """
  see https://stackoverflow.com/a/61559842/4050784
  adjust it for map keys from atom to string
  """
  @spec keys_to_strings(map) :: map
  def keys_to_strings(map) when is_map(map) do
    Map.new(map, &reduce_keys_to_strings/1)
  end

  defp reduce_keys_to_strings({key, val}) when is_map(val),
    do: {Atom.to_string(key), keys_to_strings(val)}

  defp reduce_keys_to_strings({key, val}) when is_list(val),
    do: {Atom.to_string(key), Enum.map(val, &keys_to_strings(&1))}

  defp reduce_keys_to_strings({key, val}), do: {Atom.to_string(key), val}

  @doc """
  Recursivly camelize the map keys
  usage: convert factory attrs to used for simu Graphql parmas
  """
  def camelize_map_key(map, v_trans \\ :ignore) do
    map_list =
      Enum.map(map, fn {k, v} ->
        v =
          cond do
            is_datetime?(v) ->
              DateTime.to_iso8601(v)

            is_map(v) ->
              camelize_map_key(safe_map(v))

            is_binary(v) ->
              handle_camelize_value_trans(v, v_trans)

            true ->
              v
          end

        map_to_camel({k, v})
      end)

    Enum.into(map_list, %{})
  end

  defp handle_camelize_value_trans(v, :ignore), do: v
  defp handle_camelize_value_trans(v, :downcase), do: String.downcase(v)
  defp handle_camelize_value_trans(v, :upcase), do: String.upcase(v)

  defp safe_map(%{__struct__: _} = map), do: Map.from_struct(map)
  defp safe_map(map), do: map

  defp map_to_camel({k, v}), do: {Recase.to_camel(to_string(k)), v}

  @spec snake_map_key(map) :: map
  def snake_map_key(map) do
    map_list =
      Enum.map(map, fn {k, v} ->
        v =
          cond do
            is_datetime?(v) ->
              DateTime.to_iso8601(v)

            is_map(v) ->
              snake_map_key(safe_map(v))

            true ->
              v
          end

        {Recase.to_snake(to_string(k)), v}
      end)

    Enum.into(map_list, %{})
  end

  defp is_datetime?(%DateTime{}), do: true
  defp is_datetime?(_), do: false

  def map_atom_value(attrs, :string) do
    results =
      Enum.map(attrs, fn {k, v} ->
        cond do
          v == true or v == false ->
            {k, v}

          is_atom(v) ->
            {k, v |> to_string() |> String.downcase()}

          true ->
            {k, v}
        end
      end)

    results |> Enum.into(%{})
  end

  def deep_merge(left, right), do: Map.merge(left, right, &deep_resolve/3)

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  # defp deep_resolve(_key, left = %{},right = %{}) do
  defp deep_resolve(_key, %{} = left, %{} = right), do: deep_merge(left, right)

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right), do: right
end
