# defmodule Helper.Converter.EditorToHTML.Parser do
#   @moduledoc false

#   # TODO: map should be editor_block
#   @callback parse_block(editor_json :: Map.t()) :: String.t()
# end

defmodule Helper.Converter.EditorToHTML do
  @moduledoc """
  parse editor.js's json data to raw html and sanitize it

  see https://editorjs.io/
  """

  alias Helper.Types, as: T
  alias Helper.Utils

  alias Helper.Converter.{EditorToHTML, HtmlSanitizer}
  alias EditorToHTML.{Class, Frags, Validator}

  # alias EditorToHTML.Assets.{DelimiterIcons}
  @root_class Class.article()

  @spec to_html(String.t()) :: {:ok, T.html()}
  def to_html(string) when is_binary(string) do
    with {:ok, parsed} = string_to_json(string),
         {:ok, _} <- Validator.is_valid(parsed) do
      content =
        Enum.reduce(parsed["blocks"], "", fn block, acc ->
          clean_html = block |> parse_block |> HtmlSanitizer.sanitize()
          acc <> clean_html
        end)

      viewer_class = @root_class["viewer"]
      {:ok, ~s(<div class="#{viewer_class}">#{content}</div>)}
    end
  end

  @doc "used for markdown ast to editor"
  def to_html(editor_blocks) when is_list(editor_blocks) do
    content =
      Enum.reduce(editor_blocks, "", fn block, acc ->
        clean_html = block |> Utils.keys_to_strings() |> parse_block |> HtmlSanitizer.sanitize()
        acc <> clean_html
      end)

    viewer_class = @root_class["viewer"]
    {:ok, ~s(<div class="#{viewer_class}">#{content}</div>)}
  end

  defp parse_block(%{"type" => "paragraph", "data" => %{"text" => text}}), do: "<p>#{text}</p>"

  defp parse_block(%{"type" => "header", "data" => data}), do: Frags.Header.get(data)

  defp parse_block(%{"type" => "list", "data" => data}) do
    %{"items" => items, "mode" => mode} = data

    list_wrapper_class = get_in(@root_class, ["list", "wrapper"])

    items_content =
      Enum.reduce(items, "", fn item, acc ->
        acc <> Frags.List.get_item(mode |> String.to_atom(), item)
      end)

    ~s(<div class="#{list_wrapper_class}">#{items_content}</div>)
  end

  defp parse_block(%{"type" => "table", "data" => data}) do
    %{"items" => items, "columnCount" => column_count} = data

    # IO.inspect(column_count, label: "the fuck column_count")

    groupped_items = Enum.chunk_every(items, column_count)

    rows_content =
      Enum.reduce(groupped_items, "", fn group, acc ->
        acc <> Frags.Table.get_row(group)
      end)

    table_wrapper_class = get_in(@root_class, ["table", "wrapper"])

    ~s(<div class="#{table_wrapper_class}">
         <table>
           <tbody>
             #{rows_content}
           </tbody>
         </table>
       </div>)
  end

  # defp parse_block(%{"type" => "image", "data" => data}) do
  #   url = get_in(data, ["file", "url"])

  #   "<div class=\"#{@.viewer}-image\"><img src=\"#{url}\"></div>"
  # end

  # defp parse_block(%{"type" => "delimiter", "data" => %{"type" => type}}) do
  #   svg_icon = DelimiterIcons.svg(type)

  #   # TODO:  left-wing, righ-wing staff
  #   {:skip_sanitize, "<div class=\"#{@.viewer}-delimiter\">#{svg_icon}</div>"}
  # end

  # IO.inspect(data, label: "parse linkTool")
  # TODO: parse the link-card info
  # defp parse_block(%{"type" => "linkTool", "data" => data}) do
  #   link = get_in(data, ["link"])

  #   "<div class=\"#{@.viewer}-linker\"><a href=\"#{link}\" target=\"_blank\">#{link}</a></div>"
  #   # |> IO.inspect(label: "linkTool ret")
  # end

  # IO.inspect(data, label: "parse quote")
  # defp parse_block(%{"type" => "quote", "data" => data}) do
  #   text = get_in(data, ["text"])

  #   "<div class=\"#{@.viewer}-quote\">#{text}</div>"
  #   # |> IO.inspect(label: "quote ret")
  # end

  defp parse_block(%{"type" => "code", "data" => data}) do
    text = get_in(data, ["text"])
    code = text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    lang = get_in(data, ["lang"])

    "<pre><code class=\"lang-#{lang}\">#{code}</code></pre>"
    # |> IO.inspect(label: "code ret")
  end

  defp parse_block(_block) do
    undown_block_class = @root_class["unknow_block"]
    ~s("<div class="#{undown_block_class}">[unknow block]</div>")
  end

  def string_to_json(string), do: Jason.decode(string)
end
