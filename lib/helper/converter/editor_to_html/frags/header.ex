defmodule Helper.Converter.EditorToHTML.Frags.Header do
  @moduledoc """
  parse editor.js's block fragments, use for test too

  see https://editorjs.io/
  """
  alias Helper.Metric
  alias Helper.Types, as: T

  @class get_in(Metric.Article.class_names(:html), ["header"])

  @spec get(T.editor_header()) :: T.html()
  def get(%{"eyebrowTitle" => eyebrow_title, "footerTitle" => footer_title} = data) do
    %{"text" => text, "level" => level} = data

    wrapper_class = @class["wrapper"]
    eyebrow_class = @class["eyebrow_title"]
    footer_class = @class["footer_title"]

    ~s(<div class="#{wrapper_class}">
        <div class="#{eyebrow_class}">#{eyebrow_title}</div>
        <h#{level}>#{text}</h#{level}>
        <div class="#{footer_class}">#{footer_title}</div>
      </div>)
  end

  def get(%{"eyebrowTitle" => eyebrow_title} = data) do
    %{"text" => text, "level" => level} = data

    wrapper_class = @class["wrapper"]
    eyebrow_class = @class["eyebrow_title"]

    ~s(<div class="#{wrapper_class}">
        <div class="#{eyebrow_class}">#{eyebrow_title}</div>
        <h#{level}>#{text}</h#{level}>
      </div>)
  end

  def get(%{"footerTitle" => footer_title} = data) do
    %{"text" => text, "level" => level} = data

    wrapper_class = @class["wrapper"]
    footer_class = @class["footer_title"]

    ~s(<div class="#{wrapper_class}">
        <h#{level}>#{text}</h#{level}>
        <div class="#{footer_class}">#{footer_title}</div>
      </div>)
  end

  def get(%{"text" => text, "level" => level}) do
    "<h#{level}>#{text}</h#{level}>"
  end
end
