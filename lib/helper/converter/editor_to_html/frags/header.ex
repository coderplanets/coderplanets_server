defmodule Helper.Converter.EditorToHTML.Frags.Header do
  @moduledoc """
  parse editor.js's block fragments, use for test too

  see https://editorjs.io/
  """
  alias Helper.Types, as: T
  alias Helper.Converter.EditorToHTML.Class

  @class get_in(Class.article(), ["header"])

  @spec get(String.t(), T.editor_header()) :: T.html()
  def get(id, %{"eyebrowTitle" => eyebrow_title, "footerTitle" => footer_title} = data) do
    %{"text" => text, "level" => level} = data

    ~s(<div id="#{id}" class="#{@class["wrapper"]}">
        <div class="#{@class["eyebrow_title"]}">#{eyebrow_title}</div>
        <h#{level} class="#{@class["header"]}">#{text}</h#{level}>
        <div class="#{@class["footer_title"]}">#{footer_title}</div>
      </div>)
  end

  def get(id, %{"eyebrowTitle" => eyebrow_title} = data) do
    %{"text" => text, "level" => level} = data

    ~s(<div id="#{id}" class="#{@class["wrapper"]}">
        <div class="#{@class["eyebrow_title"]}">#{eyebrow_title}</div>
        <h#{level} class="#{@class["header"]}">#{text}</h#{level}>
      </div>)
  end

  def get(id, %{"footerTitle" => footer_title} = data) do
    %{"text" => text, "level" => level} = data

    ~s(<div id="#{id}" class="#{@class["wrapper"]}">
        <h#{level} class="#{@class["header"]}">#{text}</h#{level}>
        <div class="#{@class["footer_title"]}">#{footer_title}</div>
      </div>)
  end

  def get(id, %{"text" => text, "level" => level} = data) do
    ~s(<h#{level} id="#{id}">#{text}</h#{level}>)
  end
end
