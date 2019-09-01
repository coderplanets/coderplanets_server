defmodule Helper.RichTextParser do
  @moduledoc """
  parse editor.js's json format to raw html and more

  see https://editorjs.io/
  """
  @html_class_prefix "cps-viewer"

  def convert_to_html(string) when is_binary(string) do
    with {:ok, parsed} = string_to_json(string),
         true <- valid_editor_data?(parsed) do
      content =
        Enum.reduce(parsed["blocks"], "", fn block, acc ->
          acc <> parse_block(block)
        end)

      "<div class=\"#{@html_class_prefix}\">#{content}<div>"
      # |> IO.inspect(label: "hello")
    end
  end

  defp parse_block(%{"type" => "header", "data" => data}) do
    # IO.inspect(data, label: "parse header")
    text = get_in(data, ["text"])
    level = get_in(data, ["level"])

    "<h#{level}>#{text}</h#{level}>"
  end

  defp parse_block(%{"type" => "paragraph", "data" => data}) do
    # IO.inspect(data, label: "parse paragraph")
    text = get_in(data, ["text"])

    "<p>#{text}</p>"
  end

  defp parse_block(%{"type" => "image", "data" => data}) do
    IO.inspect(data, label: "parse image")
    url = get_in(data, ["file", "url"])

    "<div class=\"#{@html_class_prefix}-image\"><img src=\"#{url}\"></div>"
    |> IO.inspect(label: "iamge ret")
  end

  # defp parse_block(%{"type" => "list", "data" => data}) do
  #   IO.inspect(data, label: "parse list")
  # end

  # defp parse_block(%{"type" => "delimiter", "data" => data}) do
  #   IO.inspect(data, label: "parse delimiter")
  # end

  # defp parse_block(%{"type" => "linkTool", "data" => data}) do
  #   IO.inspect(data, label: "parse linkTool")
  #   data |> get_in(["link"]) |> IO.inspect(label: "linkTool ret")
  # end

  # defp parse_block(%{"type" => "quote", "data" => data}) do
  #   IO.inspect(data, label: "parse quote")
  #   data |> get_in(["text"]) |> IO.inspect(label: "quote ret")
  # end

  defp parse_block(block) do
    IO.puts(".")
    ""
    # IO.inspect(block, label: "parse unknow")
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
