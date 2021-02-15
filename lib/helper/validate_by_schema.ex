defmodule Helper.ValidateBySchema do
  @moduledoc """
  validate json data by given schema, mostly used in editorjs validator

  currently support boolean / string / number / enum
  """

  @doc """
  cast data by given schema

  e.g:
  schema = %{
    checked: [:boolean],
    hideLabel: [:boolean],
    label: [:string],
    labelType: [:string],
    indent: [enum: [0, 1, 2, 3, 4]],
    text: [:string]
  }

  data = %{checked: true, label: "done"}
  ValidateBySchema.cast(schema, data)
  """
  def cast(schema, data) do
    schema_fields = Map.keys(schema)

    errors_info =
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

    case errors_info do
      [] -> {:ok, :pass}
      _ -> {:error, errors_info}
    end
  end

  # boolean field
  defp match(field, nil, [:boolean, required: false]), do: done(field, nil)

  defp match(field, value, [:boolean, required: false]) when is_boolean(value) do
    done(field, value)
  end

  defp match(field, value, [:boolean]) when is_boolean(value), do: done(field, value)
  defp match(field, value, [:boolean, required: false]), do: error(field, value, :boolean)
  defp match(field, value, [:boolean]), do: error(field, value, :boolean)

  # string field
  defp match(field, nil, [:string, required: false]), do: done(field, nil)

  defp match(field, value, [:string, required: false]) when is_binary(value) do
    done(field, value)
  end

  defp match(field, value, [:string]) when is_binary(value), do: done(field, value)
  defp match(field, value, [:string, required: false]), do: error(field, value, :string)
  defp match(field, value, [:string]), do: error(field, value, :string)

  # number field
  defp match(field, nil, [:number, required: false]), do: done(field, nil)

  defp match(field, value, [:number, required: false]) when is_number(value) do
    done(field, value)
  end

  defp match(field, value, [:number]) when is_number(value), do: done(field, value)
  defp match(field, value, [:number, required: false]), do: error(field, value, :number)
  defp match(field, value, [:number]), do: error(field, value, :number)

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
           field: "#{field |> to_string}",
           message: "should be: #{enum |> Enum.join(" | ") |> to_string}"
         }}
    end
  end

  defp done(field, value), do: {:ok, %{field: field, value: value}}

  defp error(field, value, schema) do
    {:error, %{field: field |> to_string, value: value, message: "should be: #{schema}"}}
  end
end
