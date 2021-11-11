defmodule Helper.Converter.EditorToHTML do
  @moduledoc """
  parse editor.js's json data to raw html and sanitize it

  see https://editorjs.io/
  """

  alias Helper.Types, as: T
  alias Helper.Utils

  alias Helper.Converter.{Article, EditorToHTML, HtmlSanitizer}
  alias EditorToHTML.{Class, Frags}

  # alias EditorToHTML.Assets.{DelimiterIcons}
  @root_class Class.article()

  @spec to_html(Map.t()) :: {:ok, T.html()}
  def to_html(editor_map) when is_map(editor_map) do
    content =
      Enum.reduce(editor_map["blocks"], "", fn block, acc ->
        clean_html = block |> parse_block |> HtmlSanitizer.sanitize()
        acc <> clean_html
      end)

    viewer_class = @root_class["viewer"]
    {:ok, ~s(<div class="#{viewer_class}">#{content}</div>)}
  end

  @spec to_html(String.t()) :: {:ok, T.html()}
  def to_html(string) when is_binary(string) do
    with {:ok, editor_map} <- Article.to_editor_map(string) do
      to_html(editor_map)
    end
  end

  @doc "used for markdown ast to editor"
  def to_html(editor_blocks) when is_list(editor_blocks) do
    with {:ok, editor_blocks} <- Article.to_editor_map(editor_blocks) do
      content =
        Enum.reduce(editor_blocks, "", fn block, acc ->
          clean_html = block |> parse_block |> HtmlSanitizer.sanitize()

          acc <> clean_html
        end)

      viewer_class = @root_class["viewer"]
      {:ok, ~s(<div class="#{viewer_class}">#{content}</div>)}
    end
  end

  defp parse_block(%{"id" => id, "type" => "paragraph", "data" => %{"text" => text}}) do
    ~s(<p id="#{id}">#{text}</p>)
  end

  defp parse_block(%{"id" => id, "type" => "header", "data" => data}) do
    Frags.Header.get(id, data)
  end

  defp parse_block(%{"id" => id, "type" => "quote", "data" => data}) do
    Frags.Quote.get(id, data)
  end

  defp parse_block(%{"id" => id, "type" => "list", "data" => data}) do
    %{"items" => items, "mode" => mode} = data

    list_wrapper_class = get_in(@root_class, ["list", "wrapper"])

    items_content =
      Enum.reduce(items, "", fn item, acc ->
        acc <> Frags.List.get_item(mode |> String.to_atom(), item)
      end)

    ~s(<div id="#{id}" class="#{list_wrapper_class}">#{items_content}</div>)
  end

  defp parse_block(%{"id" => id, "type" => "table", "data" => data}) do
    %{"items" => items, "columnCount" => column_count} = data

    groupped_items = Enum.chunk_every(items, column_count)

    rows_content =
      Enum.reduce(groupped_items, "", fn group, acc ->
        acc <> Frags.Table.get_row(group)
      end)

    table_wrapper_class = get_in(@root_class, ["table", "wrapper"])

    ~s(<div id="#{id}" class="#{table_wrapper_class}">
         <table>
           <tbody>
             #{rows_content}
           </tbody>
         </table>
       </div>)
  end

  defp parse_block(%{"id" => id, "type" => "image", "data" => %{"mode" => "single"} = data}) do
    %{"items" => items} = data

    image_wrapper_class = get_in(@root_class, ["image", "wrapper"])

    items_content = Frags.Image.get_item(:single, List.first(items))
    caption_content = Frags.Image.get_caption(:html, List.first(items))

    ~s(<div id="#{id}" class="#{image_wrapper_class}">#{items_content}#{caption_content}</div>)
  end

  defp parse_block(%{"id" => id, "type" => "image", "data" => %{"mode" => "jiugongge"} = data}) do
    %{"items" => items} = data

    image_wrapper_class = get_in(@root_class, ["image", "wrapper"])
    content_wrapper_class = get_in(@root_class, ["image", "jiugongge_image_wrapper"])

    items_content =
      Enum.reduce(items, "", fn item, acc ->
        acc <> Frags.Image.get_item(:jiugongge, item)
      end)

    ~s(<div id="#{id}" class="#{image_wrapper_class}">
      <div class="#{content_wrapper_class}">
      #{items_content}
      </div>
    </div>)
  end

  defp parse_block(%{"id" => id, "type" => "image", "data" => %{"mode" => "gallery"} = data}) do
    %{"items" => items} = data

    image_wrapper_class = get_in(@root_class, ["image", "wrapper"])
    content_wrapper_class = get_in(@root_class, ["image", "gallery_image_wrapper"])
    inner_wrapper_class = get_in(@root_class, ["image", "gallery_image_inner"])

    items_content =
      Enum.reduce(items, "", fn item, acc ->
        acc <> Frags.Image.get_item(:gallery, item)
      end)

    minimap_content = Frags.Image.get_minimap(items)

    ~s(<div id="#{id}" class="#{image_wrapper_class}">
        <div class="#{content_wrapper_class}">
          <div class="#{inner_wrapper_class}">
          #{items_content}
          </div>
        </div>
        #{minimap_content}
      </div>)
  end

  defp parse_block(%{"id" => id, "type" => "people", "data" => %{"mode" => "gallery"} = data}) do
    %{"items" => items} = data

    # set id to each people for switch them
    items = Enum.map(items, fn item -> Map.merge(item, %{"id" => Utils.uid(:html, item)}) end)

    wrapper_class = get_in(@root_class, ["people", "wrapper"])
    gallery_wrapper_class = get_in(@root_class, ["people", "gallery_wrapper"])

    previewer_content = Frags.People.get_previewer(:gallery, items)
    card_content = Frags.People.get_card(:gallery, items)

    ~s(<div id="#{id}" class="#{wrapper_class}">
        <div class="#{gallery_wrapper_class}">
          #{previewer_content}
          #{card_content}
        </div>
      </div>)
  end

  defp parse_block(%{"id" => id, "type" => "code", "data" => data}) do
    text = get_in(data, ["text"])
    code = text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    lang = get_in(data, ["lang"])

    ~s(<pre id="#{id}"><code class=\"lang-#{lang}\">#{code}</code></pre>)
  end

  defp parse_block(_block) do
    undown_block_class = @root_class["unknow_block"]
    ~s("<div class="#{undown_block_class}">[unknow block]</div>")
  end
end
