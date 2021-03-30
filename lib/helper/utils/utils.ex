defmodule Helper.Utils do
  @moduledoc """
  unitil functions
  """
  import Ecto.Query, warn: false
  import Helper.ErrorHandler
  import Helper.ErrorCode

  import Helper.Validator.Guards, only: [g_none_empty_str: 1]

  alias Helper.{Cache, Utils}

  defdelegate map_key_stringify(map), to: Utils.Map
  defdelegate keys_to_atoms(map), to: Utils.Map
  defdelegate keys_to_strings(map), to: Utils.Map
  defdelegate camelize_map_key(map), to: Utils.Map
  defdelegate camelize_map_key(map, opt), to: Utils.Map
  defdelegate snake_map_key(map), to: Utils.Map
  defdelegate deep_merge(left, right), to: Utils.Map
  defdelegate map_atom_value(attrs, opt), to: Utils.Map

  def get_config(section, key, app \\ :groupher_server)

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
  def done({:error, reason}, with: _result), do: {:error, reason}

  def done({:ok, %{id: id}}, :status), do: {:ok, %{done: true, id: id}}
  def done({:error, _}, :status), do: {:ok, %{done: false}}

  def done(nil, queryable, id), do: {:error, not_found_formater(queryable, id)}
  def done(result, _, _), do: {:ok, result}

  def done(nil), do: {:error, "record not found."}

  # for delete_all, update_all
  # see: https://groups.google.com/forum/#!topic/elixir-ecto/1g5Pp6ceqFE
  def done({n, nil}) when is_integer(n), do: {:ok, %{done: true}}
  def done(result), do: {:ok, result}

  def done_and_cache(result, scope, expire: expire_time) do
    with {:ok, res} <- done(result) do
      Cache.put(scope, res, expire: expire_time)
      {:ok, res}
    end
  end

  def done_and_cache(result, scope) do
    with {:ok, res} <- done(result) do
      Cache.put(scope, res)
      {:ok, res}
    end
  end

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

  def integerfy(id) when is_binary(id), do: String.to_integer(id)
  def integerfy(id), do: id

  def stringfy(v) when is_binary(v), do: v
  def stringfy(v) when is_integer(v), do: to_string(v)
  def stringfy(v) when is_atom(v), do: to_string(v)
  def stringfy(v), do: v

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

  def empty_pagi_data do
    %{entries: [], total_count: 0, page_size: 0, total_pages: 1, page_number: 1}
  end

  @doc """
  ["a", "b", "c", "c"] => %{"a" => 1, "b" => 1, "c" => 2}
  """
  def count_words(words) when is_list(words) do
    Enum.reduce(words, %{}, &update_word_count/2)
  end

  defp update_word_count(word, acc) do
    Map.update(acc, to_string(word), 1, &(&1 + 1))
  end

  # see https://stackoverflow.com/a/49558074/4050784
  @spec str_occurence(String.t(), String.t()) :: Integer.t()
  def str_occurence(string, substr) when is_binary(string) and is_binary(substr) do
    len = string |> String.split(substr) |> length()
    len - 1
  end

  def str_occurence(_, _), do: "must be strings"

  @spec large_than(String.t() | Integer.t(), Integer.t()) :: true | false
  def large_than(value, target) when is_binary(value) and is_integer(target) do
    String.length(value) >= target
  end

  def large_than(value, target) when is_integer(value) and is_integer(target) do
    value >= target
  end

  @spec large_than(String.t() | Integer.t(), Integer.t(), :no_equal) :: true | false
  def large_than(value, target, :no_equal) when is_binary(value) and is_integer(target) do
    String.length(value) > target
  end

  def large_than(value, target, :no_equal) when is_integer(value) and is_integer(target) do
    value > target
  end

  @spec less_than(String.t() | Integer.t(), Integer.t()) :: true | false
  def less_than(value, target) when is_binary(value) and is_integer(target) do
    String.length(value) <= target
  end

  def less_than(value, target) when is_integer(value) and is_integer(target) do
    value <= target
  end

  @spec less_than(String.t() | Integer.t(), Integer.t(), :no_equal) :: true | false
  def less_than(value, target, :no_equal) when is_binary(value) and is_integer(target) do
    String.length(value) < target
  end

  def less_than(value, target, :no_equal) when is_integer(value) and is_integer(target) do
    value < target
  end

  @doc "html uniq id generator for editorjs"
  @spec uid(:html, map) :: String.t()
  def uid(:html, %{"id" => id}) when g_none_empty_str(id), do: id

  def uid(:html, _) do
    # number is invalid for html id(if first letter)
    Nanoid.generate(5, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
  end
end
