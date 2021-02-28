defmodule Helper.Converter.EditorToHTML.Frags.List do
  @moduledoc """
  parse editor.js's block fragments, use for test too

  see https://editorjs.io/
  """
  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Types, as: T

  @class get_in(Class.article(), ["list"])

  @spec get_item(:checklist | :unorder_list | :order_list, T.editor_list_item()) :: T.html()
  def get_item(
        :unorder_list,
        %{
          "hideLabel" => hide_label,
          "indent" => indent,
          "label" => label,
          "labelType" => label_type,
          "text" => text
        }
      ) do
    prefix_frag = frag(:unorder_list_prefix)
    label_frag = if hide_label, do: "", else: frag(:label, label_type, indent, label)
    text_frag = frag(:text, text)

    item_class = @class["list_item"]
    indent_class = @class["indent_#{indent}"]

    ~s(<div class="#{item_class} #{indent_class}">
        #{prefix_frag}
        #{label_frag}
        #{text_frag}
      </div>)
  end

  def get_item(
        :order_list,
        %{
          "hideLabel" => hide_label,
          "indent" => indent,
          "label" => label,
          "labelType" => label_type,
          "prefixIndex" => prefix_index,
          "text" => text
        }
      ) do
    prefix_frag = frag(:order_list_prefix, prefix_index)
    label_frag = if hide_label, do: "", else: frag(:label, label_type, indent, label)
    text_frag = frag(:text, text)

    item_class = @class["list_item"]
    indent_class = @class["indent_#{indent}"]

    ~s(<div class="#{item_class} #{indent_class}">
        #{prefix_frag}
        #{label_frag}
        #{text_frag}
      </div>)
  end

  def get_item(
        :checklist,
        %{
          "checked" => checked,
          "hideLabel" => hide_label,
          "indent" => indent,
          "label" => label,
          "labelType" => label_type,
          "text" => text
        }
      ) do
    # local fragments
    checkbox_frag = frag(:checkbox, checked)
    label_frag = if hide_label, do: "", else: frag(:label, label_type, indent, label)
    text_frag = frag(:checkbox, :text, text)

    item_class = @class["checklist_item"]
    indent_class = @class["indent_#{indent}"]

    ~s(<div class="#{item_class} #{indent_class}">
        #{checkbox_frag}
        #{label_frag}
        #{text_frag}
      </div>)
  end

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
