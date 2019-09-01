defmodule Helper.RichTextParser do
  @moduledoc """
  parse editor.js's json format to raw html and more

  see https://editorjs.io/
  """
  alias Helper.Sanitizer

  @html_class_prefix "cps-viewer"

  def convert_to_html(string) when is_binary(string) do
    with {:ok, parsed} = string_to_json(string),
         true <- valid_editor_data?(parsed) do
      content =
        Enum.reduce(parsed["blocks"], "", fn block, acc ->
          clean_html = block |> parse_block |> Sanitizer.sanitize()
          acc <> clean_html
        end)

      "<div class=\"#{@html_class_prefix}\">#{content}<div>"
      # |> IO.inspect(label: "hello")
    end
  end

  # IO.inspect(data, label: "parse header")
  defp parse_block(%{"type" => "header", "data" => data}) do
    text = get_in(data, ["text"])
    level = get_in(data, ["level"])

    "<h#{level}>#{text}</h#{level}>"
  end

  # IO.inspect(data, label: "parse paragraph")
  defp parse_block(%{"type" => "paragraph", "data" => data}) do
    text = get_in(data, ["text"])

    "<p>#{text}</p>"
  end

  # IO.inspect(data, label: "parse image")
  defp parse_block(%{"type" => "image", "data" => data}) do
    url = get_in(data, ["file", "url"])

    "<div class=\"#{@html_class_prefix}-image\"><img src=\"#{url}\"></div>"
    # |> IO.inspect(label: "iamge ret")
  end

  defp parse_block(%{"type" => "list", "data" => %{"style" => "unordered", "items" => items}}) do
    content =
      Enum.reduce(items, "", fn item, acc ->
        acc <> "<li>#{item}</li>"
      end)

    "<ul>#{content}</ul>"
  end

  defp parse_block(%{"type" => "list", "data" => %{"style" => "ordered", "items" => items}}) do
    content =
      Enum.reduce(items, "", fn item, acc ->
        acc <> "<li>#{item}</li>"
      end)

    "<ol>#{content}</ol>"
  end

  defp parse_block(%{"type" => "delimiter"}) do
    "<div class=\"#{@html_class_prefix}-delimiter\" />"
  end

  # IO.inspect(data, label: "parse linkTool")
  # TODO: parse the link-card info
  defp parse_block(%{"type" => "linkTool", "data" => data}) do
    link = get_in(data, ["link"])

    "<div class=\"#{@html_class_prefix}-linker\"><a src=\"#{link}\" target=\"_blank\" /></div>"
    # |> IO.inspect(label: "linkTool ret")
  end

  # IO.inspect(data, label: "parse quote")
  defp parse_block(%{"type" => "quote", "data" => data}) do
    text = get_in(data, ["text"])

    "<div class=\"#{@html_class_prefix}-quote\">#{text}</div>"
    # |> IO.inspect(label: "quote ret")
  end

  defp parse_block(_block) do
    # IO.puts("[unknow block]")
    "[unknow block]"
  end

  def string_to_json(string), do: Jason.decode(string)

  defp valid_editor_data?(map) when is_map(map) do
    Map.has_key?(map, "time") and
      Map.has_key?(map, "version") and
      Map.has_key?(map, "blocks") and
      is_list(map["blocks"]) and
      is_binary(map["version"]) and
      is_integer(map["time"])
  end
end
