defmodule Helper.Converter.EditorToHTML.Frags.List do
  @moduledoc """
  parse editor.js's block fragments, use for test too

  see https://editorjs.io/
  """
  alias Helper.Metric

  @class get_in(Metric.Article.class_names(:html), ["list"])

  def get_item(:checklist, %{
        "checked" => checked,
        "hideLabel" => hide_label,
        "indent" => indent,
        "label" => label,
        "labelType" => label_type,
        "text" => text
      }) do
    # local fragments
    checkbox_frag = frag(:checkbox, checked)
    label_frag = if hide_label, do: "", else: frag(:label, label_type, indent, label)
    text_frag = frag(:checkbox, :text, text)

    item_class = @class["checklist_item"]

    ~s(<div class="#{item_class}">
        #{checkbox_frag}
        #{label_frag}
        #{text_frag}
      </div>)
  end

  def frag(:label, label_type, indent, label) do
    label_class = @class["label"]
    label_type_class = @class["label__#{label_type}"]

    ~s(<div class="#{label_class} #{label_type_class}" data-index="#{indent}">
        #{label}
      </div>)
  end

  @spec frag(:checkbox, Boolean.t()) :: String.t()
  def frag(:checkbox, _checked) do
    checked_svg = svg(:checked)

    ~s(<div class="checklist__item-checkbox checklist__item-check-sign-active">
        <div class="checklist__item-check-sign">
        #{checked_svg}
        </div>
      </div>)
  end

  def frag(:text, text) do
    text_class = @class["text"]

    ~s(<div class="#{text_class}">
        #{text}
      </div>)
  end

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
