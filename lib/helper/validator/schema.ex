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

  defp match(field, nil, enum: _, required: false), do: done(field, nil)

  defp match(field, value, enum: enum, required: _) do
    match(field, value, enum: enum)
  end

  defp match(field, value, enum: enum) do
    case value in enum do
      true ->
        {:ok, value}

      false ->
        {:error,
         %{
           field: field,
           message: "should be: #{enum |> Enum.join(" | ")}"
         }}
    end
  end

  defp match(field, value, [type | options]) do
    match(field, value, type, options)
  end

  defp match(field, nil, _type, [{:required, false} | _options]) do
    done(field, nil)
  end

  defp match(field, value, type, [{:required, _} | options]) do
    match(field, value, type, options)
  end

  # custom validate logic
  defp match(field, value, :string, [{:min, min} | options])
       when is_binary(value) and is_integer(min) do
    case String.length(value) >= min do
      true ->
        match(field, value, :string, options)

      false ->
        error(field, value, :min, min)
    end
  end

  defp match(field, value, :number, [{:min, min} | options])
       when is_integer(value) and is_integer(min) do
    case value >= min do
      true ->
        match(field, value, :number, options)

      false ->
        error(field, value, :min, min)
    end
  end

  # custom validate logic end

  # main type
  defp match(field, value, :string, []) when is_binary(value) do
    done(field, value)
  end

  defp match(field, value, :number, []) when is_integer(value) do
    done(field, value)
  end

  defp match(field, value, :list, []) when is_list(value) do
    done(field, value)
  end

  defp match(field, value, :boolean, []) when is_boolean(value) do
    done(field, value)
  end

  # main type end

  defp match(field, value, _type, [option]) when is_tuple(option) and not is_nil(value) do
    {k, v} = option
    error(field, value, option: "#{to_string(k)}: #{to_string(v)}")
  end

  defp match(field, value, _type, [_option]) when not is_nil(value) do
    error(field, value, :option)
  end

  defp match(field, value, type, _) do
    error(field, value, type)
  end

  defp done(field, value), do: {:ok, %{field: field, value: value}}

  defp error(field, value, :min, min) do
    {:error, %{field: field |> to_string, value: value, message: "min size: #{min}"}}
  end

  defp error(field, value, option: option) do
    {:error, %{field: field |> to_string, value: value, message: "unknow option: #{option}"}}
  end

  defp error(field, value, :option) do
    {:error, %{field: field |> to_string, value: value, message: "unknow option"}}
  end

  defp error(field, value, schema) do
    {:error, %{field: field |> to_string, value: value, message: "should be: #{schema}"}}
  end
end
