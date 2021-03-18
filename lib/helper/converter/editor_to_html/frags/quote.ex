defmodule Helper.Converter.EditorToHTML.Frags.Quote do
  @moduledoc """
  parse editor.js's block fragments, use for test too

  see https://editorjs.io/
  """
  import Helper.Validator.Guards, only: [g_none_empty_str: 1]

  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Types, as: T
  alias Helper.Utils

  @class get_in(Class.article(), ["quote"])

  @spec get(T.editor_quote()) :: T.html()
  def get(%{"mode" => "short", "text" => text} = data) do
    anchor_id = Utils.uid(:html, data)

    ~s(<blockquote id="#{anchor_id}" class="#{@class["short_wrapper"]}">
        <div class="#{@class["text"]}">#{text}</div>
      </blockquote>)
  end

  def get(%{"mode" => "long", "text" => text, "caption" => caption} = data)
      when g_none_empty_str(caption) do
    caption_content = frag(:caption, caption)
    anchor_id = Utils.uid(:html, data)

    ~s(<blockquote id="#{anchor_id}" class="#{@class["long_wrapper"]}">
        <div class="#{@class["text"]}">#{text}</div>
        #{caption_content}
      </blockquote>)
  end

  def get(%{"mode" => "long", "text" => text}) do
    ~s(<blockquote class="#{@class["long_wrapper"]}">
        <div class="#{@class["text"]}">#{text}</div>
      </blockquote>)
  end

  @spec frag(:caption, String.t()) :: T.html()
  def frag(:caption, caption) do
    ~s(<div class="#{@class["caption"]}">
        <div class="#{@class["caption_line"]}"/>
        <div class="#{@class["caption_text"]}">#{caption}</div>
      </div>)
  end
end
