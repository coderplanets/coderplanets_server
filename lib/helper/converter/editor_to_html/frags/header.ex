defmodule Helper.Converter.EditorToHTML.Frags.Header do
  @moduledoc """
  parse editor.js's block fragments, use for test too

  see https://editorjs.io/
  """
  alias Helper.Types, as: T
  alias Helper.Utils

  alias Helper.Converter.EditorToHTML.Class

  @class get_in(Class.article(), ["header"])

  @spec get(T.editor_header()) :: T.html()
  def get(%{"eyebrowTitle" => eyebrow_title, "footerTitle" => footer_title} = data) do
    %{"text" => text, "level" => level} = data
    anchor_id = Utils.uid(:html, data)

    ~s(<div id="#{anchor_id}" class="#{@class["wrapper"]}">
        <div class="#{@class["eyebrow_title"]}">#{eyebrow_title}</div>
        <h#{level} class="#{@class["header"]}">#{text}</h#{level}>
        <div class="#{@class["footer_title"]}">#{footer_title}</div>
      </div>)
  end

  def get(%{"eyebrowTitle" => eyebrow_title} = data) do
    %{"text" => text, "level" => level} = data
    anchor_id = Utils.uid(:html, data)

    ~s(<div id="#{anchor_id}" class="#{@class["wrapper"]}">
        <div class="#{@class["eyebrow_title"]}">#{eyebrow_title}</div>
        <h#{level} class="#{@class["header"]}">#{text}</h#{level}>
      </div>)
  end

  def get(%{"footerTitle" => footer_title} = data) do
    %{"text" => text, "level" => level} = data
    anchor_id = Utils.uid(:html, data)

    ~s(<div id="#{anchor_id}" class="#{@class["wrapper"]}">
        <h#{level} class="#{@class["header"]}">#{text}</h#{level}>
        <div class="#{@class["footer_title"]}">#{footer_title}</div>
      </div>)
  end

  def get(%{"text" => text, "level" => level} = data) do
    anchor_id = Utils.uid(:html, data)

    ~s(<h#{level} id="#{anchor_id}">#{text}</h#{level}>)
  end
end
