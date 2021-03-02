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

    image_wrapper_class = @class["single_image_wrapper"]
    image_class = @class["single_image"]

    ~s(<div class="#{image_wrapper_class}">
        <a href=#{src} class="glightbox" data-glightbox="type:image;description: #{caption}">
          <img class="#{image_class}" style="width:#{width}; height:#{height}" src="#{src}" alt="image" />
        </a>
       </div>)
  end

  def get_item(:single, %{"src" => src} = data) do
    caption = get_caption(data)

    image_wrapper_class = @class["single_image_wrapper"]
    image_class = @class["single_image"]

    ~s(<div class="#{image_wrapper_class}">
        <a href=#{src} class="glightbox" data-glightbox="type:image;description: #{caption}">
          <img class="#{image_class}" src="#{src}" alt="image" />
        </a>
      </div>)
  end

  def get_item(:jiugongge, %{"src" => src} = data) do
    caption = get_caption(data)
    # image_wrapper_class = @class["jiugongge-image"]

    jiugongge_image_block_class = @class["jiugongge_image_block"]
    image_class = @class["jiugongge_image"]

    ~s(<div class="#{jiugongge_image_block_class}">
        <a href=#{src} class="glightbox" data-glightbox="type:image;description: #{caption}">
          <img class="#{image_class}" src="#{src}" alt="image" />
        </a>
      </div>)
  end

  def get_item(:gallery, %{"src" => src, "index" => index} = data) do
    caption = get_caption(data)

    gallery_image_block_class = @class["gallery_image_block"]
    image_class = @class["gallery_image"]

    # IO.inspect(index, label: "index -> ")
    ~s(<div class="#{gallery_image_block_class}">
        <a href=#{src} class="glightbox" data-glightbox="type:image;description: #{caption}">
          <img class="#{image_class}" src="#{src}" alt="image" data-index="#{index}" />
        </a>
      </div>)
  end

  @spec get_minimap([T.editor_image_item()]) :: T.html()
  def get_minimap(items) do
    wrapper_class = @class["gallery_minimap"]

    items_content =
      Enum.reduce(items, "", fn item, acc ->
        acc <> frag(:minimap_image, item)
      end)

    ~s(<div class="#{wrapper_class}">
        #{items_content}
       </div>)
  end

  defp frag(:minimap_image, %{"src" => src, "index" => index}) do
    image_class = @class["gallery_minimap_image"]

    ~s(<img class="#{image_class}" src="#{src}" data-index="#{index}"/>)
  end

  def get_caption(%{"caption" => caption}) when g_none_empty_str(caption), do: caption
  def get_caption(_), do: ""

  def get_caption(:html, %{"caption" => caption}) when g_none_empty_str(caption) do
    image_caption = @class["image_caption"]
    ~s(<div class="#{image_caption}">#{caption}</div>)
  end

  def get_caption(:html, _), do: ""

  # @spec frag(:checkbox, :text, String.t()) :: T.html()
  # def frag(:checkbox, :text, text) do
  #   text_class = @class["checklist_text"]

  #   ~s(<div class="#{text_class}">
  #       #{text}
  #     </div>)
  # end

  # defp svg(type) do
  #   # workarround for https://github.com/rrrene/html_sanitize_ex/issues/48
  #   svg_frag(type) |> String.replace(" viewBox=\"", " viewbox=\"")
  # end

  # defp svg_frag(:checked) do
  #   ~s(<svg t="1592049095081" width="20px" height="20px" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="9783"><path d="M853.333333 256L384 725.333333l-213.333333-213.333333" p-id="9784"></path></svg>)
  # end
end
