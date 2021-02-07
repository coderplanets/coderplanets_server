defmodule Helper.Converter.EditorToHtml do
  @moduledoc """
  parse editor.js's json data to raw html and sanitize it

  see https://editorjs.io/
  """
  import Helper.Utils, only: [get_config: 2]

  alias Helper.Converter.HtmlSanitizer
  alias Helper.Converter.EditorToHtml.Assets
  alias Helper.Utils

  alias Assets.{DelimiterIcons}

  @article_viewer_tag get_config(:general, :article_viewer_tag)

  @spec to_html(binary | maybe_improper_list) :: false | {:ok, <<_::64, _::_*8>>}
  def to_html(string) when is_binary(string) do
    with {:ok, parsed} = string_to_json(string),
         true <- valid_editor_data?(parsed) do
      content =
        Enum.reduce(parsed["blocks"], "", fn block, acc ->
          clean_html = block |> parse_block |> HtmlSanitizer.sanitize()
          acc <> clean_html
        end)

      {:ok, "<div class=\"#{@article_viewer_tag}\">#{content}<div>"}
    end
  end

  @desc "used for markdown ast to editor"
  def to_html(editor_blocks) when is_list(editor_blocks) do
    content =
      Enum.reduce(editor_blocks, "", fn block, acc ->
        clean_html = block |> Utils.keys_to_strings() |> parse_block |> HtmlSanitizer.sanitize()
        acc <> clean_html
      end)

    {:ok, "<div class=\"#{@article_viewer_tag}\">#{content}<div>"}
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

    "<div class=\"#{@article_viewer_tag}-image\"><img src=\"#{url}\"></div>"
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

  # IO.inspect(items, label: "checklist items")
  # TODO:  add item class
  defp parse_block(%{"type" => "checklist", "data" => %{"items" => items}}) do
    content =
      Enum.reduce(items, "", fn item, acc ->
        text = Map.get(item, "text")
        checked = Map.get(item, "checked")

        case checked do
          true ->
            acc <> "<div><input type=\"checkbox\" checked />#{text}</div>"

          false ->
            acc <> "<div><input type=\"checkbox\" />#{text}</div>"
        end
      end)

    "<div class=\"#{@article_viewer_tag}-checklist\">#{content}</div>"
    # |> IO.inspect(label: "jjj")
  end

  defp parse_block(%{"type" => "delimiter", "data" => %{"type" => type}}) do
    svg_icon = DelimiterIcons.svg(type)

    # TODO:  left-wing, righ-wing staff
    {:skip_sanitize, "<div class=\"#{@article_viewer_tag}-delimiter\">#{svg_icon}</div>"}
  end

  # IO.inspect(data, label: "parse linkTool")
  # TODO: parse the link-card info
  defp parse_block(%{"type" => "linkTool", "data" => data}) do
    link = get_in(data, ["link"])

    "<div class=\"#{@article_viewer_tag}-linker\"><a href=\"#{link}\" target=\"_blank\">#{link}</a></div>"
    # |> IO.inspect(label: "linkTool ret")
  end

  # IO.inspect(data, label: "parse quote")
  defp parse_block(%{"type" => "quote", "data" => data}) do
    text = get_in(data, ["text"])

    "<div class=\"#{@article_viewer_tag}-quote\">#{text}</div>"
    # |> IO.inspect(label: "quote ret")
  end

  defp parse_block(%{"type" => "code", "data" => data}) do
    text = get_in(data, ["text"])
    code = text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    lang = get_in(data, ["lang"])

    "<pre><code class=\"lang-#{lang}\">#{code}</code></pre>"
    # |> IO.inspect(label: "code ret")
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
