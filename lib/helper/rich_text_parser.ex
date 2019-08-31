defmodule Helper.RichTextParser do
  @moduledoc """
  parse editor.js's json format to raw html and more

  see https://editorjs.io/
  """

  def string_to_json(string) do
    Jason.decode(string)
  end
end
