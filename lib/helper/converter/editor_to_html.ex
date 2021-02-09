defmodule Helper.Converter.ErrorHint do
  @moduledoc """

  see https://stackoverflow.com/a/33052969/4050784
  """

  defmacro watch(type, field) do
    quote do
      @doc "give error hint when #{unquote(field)} is invalid type"
      defp parse_block(%{
             "type" => "#{unquote(type)}",
             "data" => %{
               "#{unquote(field)}" => _
             }
           }) do
        invalid_hint("#{unquote(type)}", "#{unquote(field)}")
      end
    end
  end

  defmacro watch(type, field1, field2) do
    quote do
      @doc "give error hint when #{unquote(field1)} or #{unquote(field2)} is invalid type"
      defp parse_block(%{
             "type" => "#{unquote(type)}",
             "data" => %{
               "#{unquote(field1)}" => _,
               "#{unquote(field2)}" => _
             }
           }) do
        invalid_hint("#{unquote(type)}", "#{unquote(field1)} or #{unquote(field2)}")
      end
    end
  end
end

defmodule Helper.Converter.EditorToHtml do
  @moduledoc """
  parse editor.js's json data to raw html and sanitize it

  see https://editorjs.io/
  """
  require Helper.Converter.ErrorHint, as: ErrorHint

  import Helper.Utils, only: [get_config: 2]
  import Helper.Converter.EditorGuards
  # alias Helper.Converter.EditorGuards, as: Guards

  alias Helper.Converter.{EditorToHtml, HtmlSanitizer}
  alias Helper.{Metric, Utils}

  alias EditorToHtml.Assets.{DelimiterIcons}

  @clazz Metric.Article.class_names(:html)

  @spec to_html(binary | maybe_improper_list) :: false | {:ok, <<_::64, _::_*8>>}
  def to_html(string) when is_binary(string) do
    with {:ok, parsed} = string_to_json(string),
         true <- valid_editor_data?(parsed) do
      content =
        Enum.reduce(parsed["blocks"], "", fn block, acc ->
          clean_html = block |> parse_block |> HtmlSanitizer.sanitize()
          acc <> clean_html
        end)

      {:ok, "<div class=\"#{@clazz.viewer}\">#{content}<div>"}
    end
  end

  @desc "used for markdown ast to editor"
  def to_html(editor_blocks) when is_list(editor_blocks) do
    content =
      Enum.reduce(editor_blocks, "", fn block, acc ->
        clean_html = block |> Utils.keys_to_strings() |> parse_block |> HtmlSanitizer.sanitize()
        acc <> clean_html
      end)

    {:ok, "<div class=\"#{@clazz.viewer}\">#{content}<div>"}
  end

  defp parse_block(%{
         "type" => "header",
         "data" =>
           %{
             "text" => text,
             "level" => level,
             "eyebrowTitle" => eyebrow_title,
             "footerTitle" => footer_title
           } = data
       })
       when is_valid_header(text, level, eyebrow_title, footer_title) do
    """
    <div class="#{@clazz.header.wrapper}">
      <div class="#{@clazz.header.eyebrow_title}">#{eyebrow_title}</div>
      <h#{level}>#{text}</h#{level}>
      <div class="#{@clazz.header.footer_title}">#{footer_title}</div>
    </div>
    """
  end

  defp parse_block(%{
         "type" => "header",
         "data" =>
           %{
             "text" => text,
             "level" => level,
             "eyebrowTitle" => eyebrow_title
           } = data
       })
       when is_valid_header(text, level, eyebrow_title) do
    """
    <div class="#{@clazz.header.wrapper}">
      <div class="#{@clazz.header.eyebrow_title}">#{eyebrow_title}</div>
      <h#{level}>#{text}</h#{level}>
    </div>
    """
  end

  ErrorHint.watch("header", "eyebrowTitle")

  defp parse_block(%{
         "type" => "header",
         "data" =>
           %{
             "text" => text,
             "level" => level,
             "footerTitle" => footer_title
           } = data
       })
       when is_valid_header(text, level, footer_title) do
    """
    <div class="#{@clazz.header.wrapper}">
      <h#{level}>#{text}</h#{level}>
      <div class="#{@clazz.header.footer_title}">#{footer_title}</div>
    </div>
    """
  end

  ErrorHint.watch("header", "footerTitle")

  defp parse_block(%{
         "type" => "header",
         "data" => %{
           "text" => text,
           "level" => level
         }
       })
       when is_valid_header(text, level) do
    "<h#{level}>#{text}</h#{level}>"
  end

  ErrorHint.watch("header", "text", "level")

  defp parse_block(%{"type" => "paragraph", "data" => data}) do
    text = get_in(data, ["text"])

    "<p>#{text}</p>"
  end

  defp parse_block(%{"type" => "image", "data" => data}) do
    url = get_in(data, ["file", "url"])

    "<div class=\"#{@clazz.viewer}-image\"><img src=\"#{url}\"></div>"
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

    "<div class=\"#{@clazz.viewer}-checklist\">#{content}</div>"
    # |> IO.inspect(label: "jjj")
  end

  defp parse_block(%{"type" => "delimiter", "data" => %{"type" => type}}) do
    svg_icon = DelimiterIcons.svg(type)

    # TODO:  left-wing, righ-wing staff
    {:skip_sanitize, "<div class=\"#{@clazz.viewer}-delimiter\">#{svg_icon}</div>"}
  end

  # IO.inspect(data, label: "parse linkTool")
  # TODO: parse the link-card info
  defp parse_block(%{"type" => "linkTool", "data" => data}) do
    link = get_in(data, ["link"])

    "<div class=\"#{@clazz.viewer}-linker\"><a href=\"#{link}\" target=\"_blank\">#{link}</a></div>"
    # |> IO.inspect(label: "linkTool ret")
  end

  # IO.inspect(data, label: "parse quote")
  defp parse_block(%{"type" => "quote", "data" => data}) do
    text = get_in(data, ["text"])

    "<div class=\"#{@clazz.viewer}-quote\">#{text}</div>"
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
    "<div class=\"#{@clazz.unknow_block}\">[unknow block]</div>"
  end

  defp invalid_hint(part, message) do
    "<div class=\"#{@clazz.invalid_block}\">[invalid-block] #{part}:#{message}</div>"
  end

  # defp invalid_hint(part, message) do
  #   "<div class=\"#{@clazz.invalid_block}\">[invalid-block] #{part}:#{message}</div>"
  # end

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
