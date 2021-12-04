defmodule Helper.Converter.EditorToHTML.Validator do
  @moduledoc false

  alias Helper.{Converter, Validator}

  alias Validator.Schema
  alias Converter.EditorToHTML.Validator.EditorSchema

  @normal_blocks ["header", "paragraph", "quote"]

  # blocks with "items" fields (has many children item)
  @children_blocks ["list", "table", "image", "people"]

  # all the supported blocks
  @supported_blocks @normal_blocks ++ @children_blocks

  @spec is_valid(map) :: {:error, map} | {:ok, :pass}
  def is_valid(data) when is_map(data) do
    with {:ok, _} <- validate_editor_fmt(data),
         blocks <- Map.get(data, "blocks") do
      try do
        validate_blocks(blocks)
      rescue
        e in MatchError ->
          format_parse_error(e)

        e in RuntimeError ->
          format_parse_error(e)

        _e ->
          format_parse_error()
      end
    end
  end

  defp validate_editor_fmt(data) do
    try do
      validate_with("editor", EditorSchema.get("editor"), data)
    rescue
      e in MatchError ->
        format_parse_error(e)

      _ ->
        format_parse_error()
    end
  end

  defp validate_blocks([]), do: {:ok, :pass}

  defp validate_blocks(blocks) do
    Enum.each(blocks, fn block ->
      # if error happened, will be rescued
      {:ok, _} = validate_block(block)
    end)

    {:ok, :pass}
  end

  # validate block which have no nested items
  defp validate_block(%{"type" => type, "data" => data}) when type in @normal_blocks do
    validate_with(type, EditorSchema.get(type), data)
  end

  # validate block which has mode and items
  defp validate_block(%{"type" => type, "data" => data})
       when type in @children_blocks do
    [parent: parent_schema, item: item_schema] = EditorSchema.get(type)
    validate_with(type, parent_schema, item_schema, data)
  end

  defp validate_block(%{"type" => type}) do
    raise("undown #{type} block, supported blocks: #{@supported_blocks |> Enum.join(" | ")}")
  end

  defp validate_block(e) do
    raise("undown block: #{e}, supported blocks: #{@supported_blocks |> Enum.join(" | ")}")
  end

  # validate with given schema
  defp validate_with(block, schema, data) do
    case Schema.cast(schema, data) do
      {:error, errors} ->
        {:error, message} = format_parse_error(block, errors)
        raise %MatchError{term: {:error, message}}

      _ ->
        {:ok, :pass}
    end
  end

  defp validate_with(block, parent_schema, item_schema, data) do
    with {:ok, _} <- validate_with(block, parent_schema, data),
         %{"items" => items} <- data do
      # most block with items will have mode field, if not, just ignore
      mode = Map.get(data, "mode", "")

      Enum.each(items, fn item ->
        validate_with("#{block}(#{mode})", item_schema, item)
      end)

      {:ok, :pass}
    end
  end

  defp format_parse_error(type, error_list) when is_list(error_list) do
    {:error,
     Enum.map(error_list, fn error ->
       Map.merge(error, %{block: type})
     end)}
  end

  defp format_parse_error(%MatchError{term: {:error, error}}) do
    {:error, error}
  end

  defp format_parse_error(%{message: message}) do
    {:error, message}
  end

  defp format_parse_error(), do: {:error, "undown validate error"}
end
