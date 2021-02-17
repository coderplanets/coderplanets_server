defmodule Helper.Converter.EditorToHTML.Validator do
  @moduledoc false

  alias Helper.{Utils, ValidateBySchema}

  alias Helper.Converter.EditorToHTML.Validator.Schema

  # blocks with no children items
  @simple_blocks ["header", "paragraph"]
  # blocks with "mode" and "items" fields
  @complex_blocks ["list"]

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

        e ->
          format_parse_error()
      end
    end
  end

  defp validate_editor_fmt(data) do
    validate_with("editor", Schema.get("editor"), data)
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
  defp validate_block(%{"type" => type, "data" => data}) when type in @simple_blocks do
    validate_with(type, Schema.get(type), data)
  end

  # validate block which has mode and items
  defp validate_block(%{"type" => type, "data" => %{"mode" => mode, "items" => items} = data})
       when type in @complex_blocks do
    [parent: parent_schema, item: item_schema] = Schema.get(type)
    validate_with(type, parent_schema, item_schema, data)
  end

  defp validate_block(%{"type" => "code"}) do
    # schema = %{text: [:string]}
    # case ValidateBySchema.cast(schema, data) do
    #   {:error, errors} ->
    #     format_parse_error("paragraph", errors)

    #   _ ->
    #     {:ok, :pass}
    # end
    {:ok, :pass}
  end

  defp validate_block(%{"type" => type}), do: raise("undown #{type} block")
  defp validate_block(e), do: raise("undown block: #{e}")

  # validate with given schema
  defp validate_with(block, schema, data) do
    case ValidateBySchema.cast(schema, data) do
      {:error, errors} ->
        format_parse_error(block, errors)

      _ ->
        {:ok, :pass}
    end
  end

  defp validate_with(block, parent_schema, item_schema, data) do
    case ValidateBySchema.cast(parent_schema, data) do
      {:error, errors} ->
        format_parse_error(block, errors)

      _ ->
        {:ok, :pass}
    end

    %{"mode" => mode, "items" => items} = data

    Enum.each(items, fn item ->
      case ValidateBySchema.cast(item_schema, item) do
        {:error, errors} ->
          {:error, message} = format_parse_error("#{block}(#{mode})", errors)
          raise %MatchError{term: {:error, message}}

        _ ->
          {:ok, :pass}
      end
    end)

    {:ok, :pass}
  end

  #  check if the given map has the right key-value fmt of the editorjs structure
  defp is_valid_editorjs_fmt(map) when is_map(map) do
    Map.has_key?(map, "time") and
      Map.has_key?(map, "version") and
      Map.has_key?(map, "blocks") and
      is_list(map["blocks"]) and
      is_binary(map["version"]) and
      is_integer(map["time"])
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
