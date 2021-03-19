defmodule Helper.Converter.EditorToHTML.Frags.Image do
  @moduledoc """
  parse editor.js's block fragments, use for test too

  see https://editorjs.io/
  """
  import Helper.Validator.Guards, only: [g_none_empty_str: 1]

  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Types, as: T

  @class get_in(Class.article(), ["image"])

  @spec get_item(:single | :gallery | :jiugongge, T.editor_image_item()) :: T.html()
  def get_item(
        :single,
        %{
          "src" => src,
          "width" => width,
          "height" => height
        } = data
      )
      when g_none_empty_str(width) and g_none_empty_str(height) do
    caption = get_caption(data)

    ~s(<div class="#{@class["single_image_wrapper"]}">
        <a href=#{src} class="glightbox" data-glightbox="type:image;description: #{caption}">
          <img class="#{@class["single_image"]}" style="width:#{width}; height:#{height}" src="#{
      src
    }" alt="image" />
        </a>
       </div>)
  end

  def get_item(:single, %{"src" => src} = data) do
    caption = get_caption(data)

    ~s(<div class="#{@class["single_image_wrapper"]}">
        <a href=#{src} class="glightbox" data-glightbox="type:image;description: #{caption}">
          <img class="#{@class["single_image"]}" src="#{src}" alt="image" />
        </a>
      </div>)
  end

  def get_item(:jiugongge, %{"src" => src} = data) do
    caption = get_caption(data)
    # image_wrapper_class = @class["jiugongge-image"]

    ~s(<div class="#{@class["jiugongge_image_block"]}">
        <a href=#{src} class="glightbox" data-glightbox="type:image;description: #{caption}">
          <img class="#{@class["jiugongge_image"]}" src="#{src}" alt="image" />
        </a>
      </div>)
  end

  def get_item(:gallery, %{"src" => src, "index" => index} = data) do
    caption = get_caption(data)

    # IO.inspect(index, label: "index -> ")
    ~s(<div class="#{@class["gallery_image_block"]}">
        <a href=#{src} class="glightbox" data-glightbox="type:image;description: #{caption}">
          <img class="#{@class["gallery_image"]}" src="#{src}" alt="image" data-index="#{index}" />
        </a>
      </div>)
  end

  @spec get_minimap([T.editor_image_item()]) :: T.html()
  def get_minimap(items) do
    items_content =
      Enum.reduce(items, "", fn item, acc ->
        acc <> frag(:minimap_image, item)
      end)

    ~s(<div class="#{@class["gallery_minimap"]}">
        #{items_content}
       </div>)
  end

  defp frag(:minimap_image, %{"src" => src, "index" => index}) do
    ~s(<img class="#{@class["gallery_minimap_image"]}" src="#{src}" data-index="#{index}"/>)
  end

  def get_caption(%{"caption" => caption}) when g_none_empty_str(caption), do: caption
  def get_caption(_), do: ""

  def get_caption(:html, %{"caption" => caption}) when g_none_empty_str(caption) do
    ~s(<div class="#{@class["image_caption"]}">#{caption}</div>)
  end

  def get_caption(:html, _), do: ""
end
