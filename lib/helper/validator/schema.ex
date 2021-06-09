defmodule Helper.Validator.Schema do
  @moduledoc """
  validate json data by given schema, mostly used in editorjs validator

  currently support boolean / string / number / enum
  """

  # use Helper.Validator.Schema.Matchers, [:string, :number, :list, :boolean]

  @doc """
  cast data by given schema

  ## example
  schema = %{
    checked: [:boolean],
    hideLabel: [:boolean],
    label: [:string],
    labelType: [:string],
    indent: [enum: [0, 1, 2, 3, 4]],
    text: [:string]
  }

  data = %{checked: true, label: "done"}
  Schema.cast(schema, data)
  """

  alias Helper.Utils
  import Helper.Validator.Guards, only: [g_pos_int: 1, g_not_nil: 1]

  @support_min [:string, :number]

  @spec cast(map, map) :: {:ok, :pass} | {:error, map}
  def cast(schema, data) do
    errors_info = cast_errors(schema, data)

    case errors_info do
      [] -> {:ok, :pass}
      _ -> {:error, errors_info}
    end
  end

  defp cast_errors(schema, data) do
    schema_fields = Map.keys(schema)

    Enum.reduce(schema_fields, [], fn field, acc ->
      value = get_in(data, [field])
      field_schema = get_in(schema, [field])

      case match(field, value, field_schema) do
        {:error, error} ->
          acc ++ [error]

        _ ->
          acc
      end
    end)
  end

  defp option_valid?(:string, {:min, v}) when is_integer(v), do: true
  defp option_valid?(:number, {:min, v}) when is_integer(v), do: true

  defp option_valid?(_, {:required, v}) when is_boolean(v), do: true
  defp option_valid?(:string, {:starts_with, v}) when is_binary(v), do: true
  defp option_valid?(:list, {:type, :map}), do: true
  defp option_valid?(:string, {:allow_empty, v}) when is_boolean(v), do: true
  defp option_valid?(:list, {:allow_empty, v}) when is_boolean(v), do: true

  defp option_valid?(_, _), do: false

  defp match(field, nil, enum: _, required: false), do: done(field, nil)
  defp match(field, value, enum: enum, required: _), do: match(field, value, enum: enum)

  defp match(field, value, enum: enum) do
    case value in enum do
      true ->
        {:ok, value}

      false ->
        msg = %{field: field, message: "should be: #{enum |> Enum.join(" | ")}"}
        {:error, msg}
    end
  end

  defp match(field, value, [type | options]), do: match(field, value, type, options)
  defp match(field, nil, _type, [{:required, false} | _options]), do: done(field, nil)

  defp match(field, value, type, [{:required, _} | options]) do
    match(field, value, type, options)
  end

  # custom validate logic
  ## min option for @support_min types
  defp match(field, value, type, [{:min, min} | options])
       when type in @support_min and g_not_nil(value) and g_pos_int(min) do
    case Utils.large_than(value, min) do
      true -> match(field, value, type, options)
      false -> error(field, value, :min, min)
    end
  end

  ## starts_with option for string
  defp match(field, value, type, [{:starts_with, starts} | options]) when is_binary(value) do
    case String.starts_with?(value, starts) do
      true -> match(field, value, type, options)
      false -> error(field, value, :starts_with, starts)
    end
  end

  ## item type for list
  defp match(field, value, type, [{:type, :map} | options]) when is_list(value) do
    case Enum.all?(value, &is_map(&1)) do
      true -> match(field, value, type, options)
      false -> error(field, value, :list_type_map)
    end
  end

  # allow empty for list
  defp match(field, value, _type, [{:allow_empty, false} | _options])
       when is_list(value) and value == [] do
    error(field, value, :allow_empty)
  end

  # allow empty for string
  defp match(field, value, _type, [{:allow_empty, false} | _options])
       when is_binary(value) and byte_size(value) == 0 do
    error(field, value, :allow_empty)
  end

  defp match(field, value, type, [{:allow_empty, _} | options])
       when is_binary(value) or is_list(value) do
    match(field, value, type, options)
  end

  # custom validate logic end

  # main type
  defp match(field, value, :string, []) when is_binary(value), do: done(field, value)
  defp match(field, value, :number, []) when is_integer(value), do: done(field, value)
  defp match(field, value, :list, []) when is_list(value), do: done(field, value)
  defp match(field, value, :boolean, []) when is_boolean(value), do: done(field, value)
  # main type end

  # error for option
  defp match(field, value, type, [option]) when is_tuple(option) do
    # 如果这里不判断的话会和下面的 match 冲突，是否有更好的写法？
    case option_valid?(type, option) do
      true ->
        error(field, value, type)

      # unknow option or option not valid
      false ->
        {k, v} = option
        error(field, value, option: "#{to_string(k)}: #{to_string(v)}")
    end
  end

  defp match(field, value, type, _), do: error(field, value, type)

  defp done(field, value), do: {:ok, %{field: field, value: value}}

  # custom error hint
  defp error(field, value, :min, expect) do
    {:error, %{field: field |> to_string, value: value, message: "min size: #{expect}"}}
  end

  defp error(field, value, :starts_with, expect) do
    {:error, %{field: field |> to_string, value: value, message: "should starts with: #{expect}"}}
  end

  defp error(field, value, :list_type_map) do
    {:error, %{field: field |> to_string, value: value, message: "item should be map"}}
  end

  defp error(field, value, :allow_empty) do
    {:error, %{field: field |> to_string, value: value, message: "empty is not allowed"}}
  end

  # custom error hint end

  defp error(field, value, option: option) do
    {:error, %{field: field |> to_string, value: value, message: "unknow option: #{option}"}}
  end

  defp error(field, value, schema) do
    {:error, %{field: field |> to_string, value: value, message: "should be: #{schema}"}}
  end
end
