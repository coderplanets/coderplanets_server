defmodule Helper.NestedFilter do
  @moduledoc """
  Documentation for NestedFilter.
  see: https://github.com/treble37/nested_filter
  """
  @type key :: any
  @type val :: any
  @type keys_to_select :: list
  @type predicate :: (key, val -> boolean)

  # @spec drop_by(struct, predicate) :: struct
  def drop_by(%_{} = struct, _), do: struct

  # @spec drop_by(map, predicate) :: map
  def drop_by(map, predicate) when is_map(map) do
    map
    |> Enum.reduce(%{}, fn {key, val}, acc ->
      cleaned_val = drop_by(val, predicate)

      if predicate.(key, cleaned_val) do
        acc
      else
        Map.put(acc, key, cleaned_val)
      end
    end)
  end

  # @spec drop_by(list, predicate) :: list
  def drop_by(list, predicate) when is_list(list) do
    Enum.map(list, &drop_by(&1, predicate))
  end

  def drop_by(elem, _) do
    elem
  end

  @doc """
  Take a (nested) map and filter out any keys with specified values in the
  values_to_reject list.
  """
  # @spec drop_by_value(%{any => any}, [any]) :: %{any => any}
  def drop_by_value(map, values_to_reject) when is_map(map) do
    drop_by(map, fn _, val -> val in values_to_reject end)
  end

  @doc """
  Take a (nested) map and filter out any values with specified keys in the
  keys_to_reject list.
  """
  # @spec drop_by_key(%{any => any}, [any]) :: %{any => any}
  def drop_by_key(map, keys_to_reject) when is_map(map) do
    drop_by(map, fn key, _ -> key in keys_to_reject end)
  end

  # @spec take_by(map, keys_to_select) :: map
  def take_by(map, keys_to_select) when is_map(map) do
    map
    |> Enum.reduce(%{}, fn {_key, val}, acc ->
      Map.merge(acc, take_by(val, keys_to_select))
    end)
    |> Map.merge(Map.take(map, keys_to_select))
  end

  def take_by(_elem, _) do
    %{}
  end

  @doc """
  Take a (nested) map and keep any values with specified keys in the
  keys_to_select list.
  """
  # @spec take_by_key(%{any => any}, [any]) :: %{any => any}
  def take_by_key(map, keys_to_select) when is_map(map) do
    Map.merge(take_by(map, keys_to_select), Map.take(map, keys_to_select))
  end
end
