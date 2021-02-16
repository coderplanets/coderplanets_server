defmodule Helper.Converter.EditorToHTML.Validator do
  @moduledoc false

  alias Helper.{Utils, ValidateBySchema}

  alias Helper.Converter.EditorToHTML.Validator.Schema

  # blocks with no children items
  @simple_blocks ["header", "paragraph"]

  @valid_list_mode ["checklist", "order_list", "unorder_list"]
  @valid_list_label_type ["success", "done", "todo"]
  @valid_list_indent [0, 1, 2, 3, 4]

  def is_valid(map) when is_map(map) do
    with true <- is_valid_editorjs_fmt(map) do
      blocks = map["blocks"]

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
    else
      false ->
        {:error, "invalid editor json format"}

      _ ->
        {:error, "invalid editor json"}
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
  defp validate_block(%{"type" => type, "data" => data}) when type in @simple_blocks do
    validate_with(type, Schema.get(type), data)
  end

  defp validate_block(%{"type" => "list", "data" => %{"mode" => mode, "items" => items} = data})
       when mode in @valid_list_mode and is_list(items) do
    # mode_schema = %{mode: [enum: @valid_list_mode]}
    # {:ok, _} = ValidateBySchema.cast(mode_schema, data)

    item_schema = %{
      "checked" => [:boolean],
      "hideLabel" => [:boolean],
      "label" => [:string],
      "labelType" => [enum: @valid_list_label_type],
      "indent" => [enum: @valid_list_indent],
      "text" => [:string]
    }

    Enum.each(items, fn item ->
      case ValidateBySchema.cast(item_schema, item) do
        {:error, errors} ->
          {:error, message} = format_parse_error("list(#{mode})", errors)
          raise %MatchError{term: {:error, message}}

        _ ->
          {:ok, :pass}
      end
    end)

    {:ok, :pass}
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
  defp validate_block(_), do: raise("undown block")

  # validate with given schema
  defp validate_with(block, schema, data) do
    case ValidateBySchema.cast(schema, data) do
      {:error, errors} ->
        format_parse_error(block, errors)

      _ ->
        {:ok, :pass}
    end
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