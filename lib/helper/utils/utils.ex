defmodule Helper.Utils do
  @moduledoc """
  unitil functions
  """
  import Ecto.Query, warn: false
  import Helper.ErrorHandler
  import Helper.ErrorCode

  import Helper.Validator.Guards, only: [g_none_empty_str: 1]

  alias GroupherServer.CMS
  alias Helper.{Cache, Utils}

  # Map utils
  defdelegate atom_values_to_upcase(map), to: Utils.Map
  defdelegate map_key_stringify(map), to: Utils.Map
  defdelegate keys_to_atoms(map), to: Utils.Map
  defdelegate keys_to_strings(map), to: Utils.Map
  defdelegate camelize_map_key(map), to: Utils.Map
  defdelegate camelize_map_key(map, opt), to: Utils.Map
  defdelegate snake_map_key(map), to: Utils.Map
  defdelegate deep_merge(left, right), to: Utils.Map
  defdelegate map_atom_value(attrs, opt), to: Utils.Map

  # String Utils
  defdelegate stringfy(str), to: Utils.String
  defdelegate count_words(str), to: Utils.String
  defdelegate str_occurence(string, substr), to: Utils.String

  defdelegate thread_of(artiment, opt), to: CMS.Delegate.Helper

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
  plural version of the thread
  """
  def plural(:works), do: :works
  def plural(thread), do: :"#{thread}s"

  @doc """
  like || in javascript
  """
  def ensure(nil, default_data), do: default_data
  def ensure(data, _default_value), do: data

  @doc """
  handle General {:ok, ..} or {:error, ..} return
  """
  def done(false), do: {:error, false}
  def done(true), do: {:ok, true}
  def done(nil), do: {:error, "record not found."}
  def done([]), do: {:ok, []}
  def done(:ok), do: {:ok, :pass}
  def done(nil, :boolean), do: {:ok, false}
  def done(_, :boolean), do: {:ok, true}
  def done(nil, err_msg), do: {:error, err_msg}
  def done({:ok, _}, with: result), do: {:ok, result}
  def done({:error, reason}, with: _result), do: {:error, reason}

  def done(nil, queryable, id), do: {:error, not_found_formater(queryable, id)}
  def done(result, _, _), do: {:ok, result}

  # for delete_all, update_all
  # see: https://groups.google.com/forum/#!topic/elixir-ecto/1g5Pp6ceqFE
  # def done({0, nil}), do: {:error, %{done: false}}
  def done({n, nil}) when is_integer(n), do: {:ok, %{done: true}}
  # def done({n, nil}, extra: extra) when is_integer(n), do: {:ok, %{done: true}}

  def done(result), do: {:ok, result}

  def done_and_cache(result, pool, scope, expire_sec: expire_sec) do
    with {:ok, res} <- done(result) do
      Cache.put(pool, scope, res, expire_sec: expire_sec)
      {:ok, res}
    end
  end

  def done_and_cache(result, pool, scope, expire_min: expire_min) do
    with {:ok, res} <- done(result) do
      Cache.put(pool, scope, res, expire_min: expire_min)
      {:ok, res}
    end
  end

  def done_and_cache(result, pool, scope) do
    with {:ok, res} <- done(result) do
      Cache.put(pool, scope, res)
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

  @doc """
  convert struct to normal map and remove :id field
  """
  def strip_struct(struct) when is_struct(struct) do
    struct |> Map.from_struct() |> Map.delete(:id) |> Map.delete(:__meta__)
  end

  def strip_struct(map) when is_map(map), do: map

  @doc """
  get upcase name of a module, most used for store thread in DB
  """
  def module_to_upcase(module) do
    module |> Module.split() |> List.last() |> String.upcase()
  end

  @doc """
  get atom name of a module
  """
  def module_to_atom(%{__struct__: module_struct}) do
    module_struct
    |> Module.split()
    |> List.last()
    |> String.downcase()
    |> String.to_atom()
  end

  def module_to_atom(module_struct) do
    try do
      module_struct |> struct |> module_to_atom
    rescue
      _ -> nil
    end
  end

  def to_upcase(v) when is_atom(v), do: v |> to_string |> String.upcase()
  def to_upcase(v) when is_binary(v), do: v |> String.upcase()
  def to_upcase(_), do: nil

  def uid(str_len \\ 5) do
    Nanoid.generate(str_len, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
  end

  @doc "html uniq id generator for editorjs"
  @spec uid(:html, map) :: String.t()
  def uid(:html, %{"id" => id}) when g_none_empty_str(id), do: id

  def uid(:html, _) do
    # number is invalid for html id(if first letter)
    Nanoid.generate(5, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
  end
end
