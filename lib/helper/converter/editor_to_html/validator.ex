defmodule Helper.Converter.EditorToHTML.Validator do
  @moduledoc false

  alias Helper.{Utils, ValidateBySchema}

  @valid_header_level [1, 2, 3]

  @valid_list_mode ["checklist", "order_list", "unorder_list"]
  @valid_list_label_type ["success", "done", "todo"]
  @valid_list_indent [0, 1, 2, 3, 4]

  # atoms dynamically and atoms are not
  # garbage-collected. Therefore, string should not be an untrusted value, such as
  # input received from a socket or during a web request. Consider using
  # to_existing_atom/1 instead
  # keys_to_atoms is using to_existing_atom under the hook, so we have to pre-define the
  # trusted atoms
  tursted_atoms = [
    # common
    :text,
    # header
    :level,
    :eyebrowTitle,
    :footerTitle,
    # list
    :hideLabel,
    :labelType,
    :indent,
    :checked,
    :label
  ]

  Enum.each(tursted_atoms, fn atom -> _ = atom end)

  def is_valid(map) when is_map(map) do
    with atom_map <- Utils.keys_to_atoms(map),
         true <- is_valid_editorjs_fmt(atom_map) do
      blocks = atom_map.blocks
      # validate_blocks(blocks)

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

  defp validate_block(%{type: "paragraph", data: %{text: text} = data}) do
    schema = %{text: [:string]}

    case ValidateBySchema.cast(schema, data) do
      {:error, errors} ->
        format_parse_error("paragraph", errors)

      _ ->
        {:ok, :pass}
    end
  end

  defp validate_block(%{type: "header", data: %{text: text, level: level} = data}) do
    schema = %{
      text: [:string],
      level: [enum: @valid_header_level],
      eyebrowTitle: [:string, required: false],
      footerTitle: [:string, required: false]
    }

    case ValidateBySchema.cast(schema, data) do
      {:error, errors} ->
        format_parse_error("header", errors)

      _ ->
        {:ok, :pass}
    end
  end

  defp validate_block(%{type: "list", data: %{mode: mode, items: items} = data})
       when mode in @valid_list_mode and is_list(items) do
    # mode_schema = %{mode: [enum: @valid_list_mode]}
    # {:ok, _} = ValidateBySchema.cast(mode_schema, data)

    item_schema = %{
      checked: [:boolean],
      hideLabel: [:boolean],
      label: [:string],
      labelType: [enum: @valid_list_label_type],
      indent: [enum: @valid_list_indent],
      text: [:string]
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
  end

  defp validate_block(%{type: type}), do: raise("undown #{type} block")
  defp validate_block(_), do: raise("undown block")

  #  check if the given map has the right key-value fmt of the editorjs structure
  defp is_valid_editorjs_fmt(map) when is_map(map) do
    Map.has_key?(map, :time) and
      Map.has_key?(map, :version) and
      Map.has_key?(map, :blocks) and
      is_list(map.blocks) and
      is_binary(map.version) and
      is_integer(map.time)
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
