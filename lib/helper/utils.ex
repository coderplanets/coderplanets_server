defmodule Helper.Utils do
  import Ecto.Query, warn: false
  import Helper.ErrorHandler
  import Helper.ErrorCode

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

  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  def tobe_integer(val) do
    if is_integer(val),
      do: val,
      else: val |> String.to_integer()
  end

  def repeat(times, [x]) when is_integer(x), do: to_string(for _ <- 1..times, do: x)
  def repeat(times, x), do: for(_ <- 1..times, do: x)

  def add(num, offset \\ 1) when is_integer(num) and is_integer(offset), do: num + offset

  def map_atom_value(attrs, :string) do
    Enum.map(attrs, fn {k, v} ->
      if is_atom(v) do
        {k, to_string(v)}
      else
        {k, v}
      end
    end)
    |> Enum.into(%{})
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
end
