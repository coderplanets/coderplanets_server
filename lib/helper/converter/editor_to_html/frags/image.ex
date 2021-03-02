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

    image_block_class = @class["single_image_block"]
    image_class = @class["single_image"]

    ~s(<div class="#{image_block_class}">
        <a href=#{src} class="glightbox" data-glightbox="type:image;description: #{caption}">
          <img class="#{image_class}" style="width:#{width}; height:#{height}" src="#{src}" alt="image" />
        </a>
       </div>)
  end

  def get_item(:single, %{"src" => src} = data) do
    caption = get_caption(data)

    image_block_class = @class["single_image_block"]
    image_class = @class["single_image"]

    ~s(<div class="#{image_block_class}">
        <a href=#{src} class="glightbox" data-glightbox="type:image;description: #{caption}">
          <img class="#{image_class}" src="#{src}" alt="image" />
        </a>
      </div>)
  end

  def get_caption(%{"caption" => caption}) when g_none_empty_str(caption) do
    image_caption = @class["image_caption"]
    ~s(<div class="#{image_caption}">#{caption}</div>)
  end

  def get_caption(_), do: ""

  @spec frag(:label, T.editor_list_label_type(), T.editor_list_indent(), String.t()) :: T.html()
  def frag(:label, label_type, indent, label) do
    label_class = @class["label"]
    label_type_class = @class["label__#{label_type}"]

    ~s(<div class="#{label_class} #{label_type_class}" data-index="#{indent}">
        #{label}
      </div>)
  end

  @spec frag(:unorder_list_prefix) :: T.html()
  def frag(:unorder_list_prefix) do
    unorder_list_prefix_class = @class["unorder_list_prefix"]

    ~s(<div class="#{unorder_list_prefix_class}"></div>)
  end

  @spec frag(:order_list_prefix, String.t()) :: T.html()
  def frag(:order_list_prefix, prefix_index) when is_binary(prefix_index) do
    order_list_prefix_class = @class["order_list_prefix"]

    ~s(<div class="#{order_list_prefix_class}">#{prefix_index}</div>)
  end

  @spec frag(:checkbox, Boolean.t()) :: T.html()
  def frag(:checkbox, checked) when is_boolean(checked) do
    checked_svg = svg(:checked)

    checkbox_class = @class["checklist_checkbox"]
    checkbox_checked_class = if checked, do: @class["checklist_checkbox_checked"], else: ""
    checkbox_checksign_class = @class["checklist_checksign"]

    ~s(<div class="#{checkbox_class} #{checkbox_checked_class}">
        <div class="#{checkbox_checksign_class}">
        #{checked_svg}
        </div>
      </div>)
  end

  @spec frag(:text, String.t()) :: T.html()
  def frag(:text, text) when is_binary(text) do
    text_class = @class["text"]

    ~s(<div class="#{text_class}">
        #{text}
      </div>)
  end

  @spec frag(:checkbox, :text, String.t()) :: T.html()
  def frag(:checkbox, :text, text) do
    text_class = @class["checklist_text"]

    ~s(<div class="#{text_class}">
        #{text}
      </div>)
  end

  defp svg(type) do
    # workarround for https://github.com/rrrene/html_sanitize_ex/issues/48
    svg_frag(type) |> String.replace(" viewBox=\"", " viewbox=\"")
  end

  defp svg_frag(:checked) do
    ~s(<svg t="1592049095081" width="20px" height="20px" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="9783"><path d="M853.333333 256L384 725.333333l-213.333333-213.333333" p-id="9784"></path></svg>)
  end
end
