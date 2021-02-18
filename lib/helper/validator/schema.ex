defmodule Helper.Validator.Schema do
  @moduledoc """
  validate json data by given schema, mostly used in editorjs validator

  currently support boolean / string / number / enum
  """

  use Helper.Validator.Schema.Matchers, [:string, :number, :list, :boolean]

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

  # enum
  defp match(field, nil, enum: _, required: false), do: done(field, nil)

  defp match(field, value, enum: enum, required: false) do
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

  defp done(field, value), do: {:ok, %{field: field, value: value}}

  defp error(field, value, schema) do
    {:error, %{field: field |> to_string, value: value, message: "should be: #{schema}"}}
  end
end
