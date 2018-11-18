defmodule Helper.Utils do
  @moduledoc """
  unitil functions
  """
  import Ecto.Query, warn: false
  import Helper.ErrorHandler
  import Helper.ErrorCode

  def get_config(section, key, app \\ :mastani_server)

  def get_config(section, :all, app) do
    app
    |> Application.get_env(section)
    |> case do
      nil -> ""
      config -> config
    end
  end

  def get_config(section, key, app) do
    app
    |> Application.get_env(section)
    |> case do
      nil -> ""
      config -> Keyword.get(config, key)
    end
  end

  @doc """
  handle General {:ok, ..} or {:error, ..} return
  """
  def done(nil, :boolean), do: {:ok, false}
  def done(_, :boolean), do: {:ok, true}
  def done(nil, err_msg), do: {:error, err_msg}
  def done({:ok, _}, with: result), do: {:ok, result}
  def done({:error, error}, with: _result), do: {:error, error}

  def done({:ok, %{id: id}}, :status), do: {:ok, %{done: true, id: id}}
  def done({:error, _}, :status), do: {:ok, %{done: false}}

  def done(nil, queryable, id), do: {:error, not_found_formater(queryable, id)}
  def done(result, _, _), do: {:ok, result}

  def done(nil), do: {:error, "record not found."}

  # for delete_all, update_all
  # see: https://groups.google.com/forum/#!topic/elixir-ecto/1g5Pp6ceqFE
  def done({n, nil}) when is_integer(n), do: {:ok, %{done: true}}

  # def done({:error, error}), do: {:error, error}
  def done(result), do: {:ok, result}

  @doc """
  see: https://hexdocs.pm/absinthe/errors.html#content for error format
  """
  def handle_absinthe_error(resolution, err_msg, code) when is_integer(code) do
    resolution
    |> Absinthe.Resolution.put_result({:error, message: err_msg, code: code})
  end

  def handle_absinthe_error(resolution, err_msg) when is_list(err_msg) do
    # %{resolution | value: [], errors: transform_errors(changeset)}
    resolution
    # |> Absinthe.Resolution.put_result({:error, err_msg})
    |> Absinthe.Resolution.put_result({:error, message: err_msg, code: ecode()})
  end

  def handle_absinthe_error(resolution, err_msg) when is_binary(err_msg) do
    resolution
    # |> Absinthe.Resolution.put_result({:error, err_msg})
    |> Absinthe.Resolution.put_result({:error, message: err_msg, code: ecode()})
  end

  def map_key_stringify(%{__struct__: _} = map) when is_map(map) do
    map = Map.from_struct(map)
    map |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, to_string(key), val) end)
  end

  def map_key_stringify(map) when is_map(map) do
    map |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, to_string(key), val) end)
  end

  @doc """
  Recursivly camelize the map keys
  usage: convert factory attrs to used for simu Graphql parmas
  """
  def camelize_map_key(map) do
    map_list =
      Enum.map(map, fn {k, v} ->
        v =
          cond do
            is_datetime?(v) ->
              DateTime.to_iso8601(v)

            is_map(v) ->
              camelize_map_key(safe_map(v))

            true ->
              v
          end

        map_to_camel({k, v})
      end)

    Enum.into(map_list, %{})
  end

  defp safe_map(%{__struct__: _} = map), do: Map.from_struct(map)
  defp safe_map(map), do: map

  defp map_to_camel({k, v}), do: {Recase.to_camel(to_string(k)), v}

  def is_datetime?(%DateTime{}), do: true
  def is_datetime?(_), do: false

  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  def tobe_integer(val) do
    if is_integer(val),
      do: val,
      else: val |> String.to_integer()
  end

  # TODO: enhance, doc
  def repeat(times, [x]) when is_integer(x), do: to_string(for _ <- 1..times, do: x)
  def repeat(times, x), do: for(_ <- 1..times, do: x)

  # TODO: enhance, doc
  def add(num, offset \\ 1) when is_integer(num) and is_integer(offset), do: num + offset

  # TODO: enhance, doc
  def pick_by(source, key) when is_list(source) and is_atom(key) do
    Enum.reduce(source, [], fn t, acc ->
      acc ++ [Map.get(t, key)]
    end)
  end

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

  def empty_pagi_data do
    %{entries: [], total_count: 0, page_size: 0, total_pages: 1, page_number: 1}
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  # defp deep_resolve(_key, left = %{},right = %{}) do
  defp deep_resolve(_key, %{} = left, %{} = right), do: deep_merge(left, right)

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right), do: right

  @doc """
  ["a", "b", "c", "c"] => %{"a" => 1, "b" => 1, "c" => 2}
  """
  def count_words(words) when is_list(words) do
    Enum.reduce(words, %{}, &update_word_count/2)
  end

  defp update_word_count(word, acc) do
    Map.update(acc, to_string(word), 1, &(&1 + 1))
  end
end
