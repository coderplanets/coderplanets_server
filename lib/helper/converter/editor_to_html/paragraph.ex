defmodule Helper.Converter.EditorToHTML.Paragraph do
  @moduledoc """
  parse editor.js's paragraph block

  see https://editorjs.io/
  """
  defmacro __using__(_opts) do
    quote do
      defp parse_block(%{"type" => "paragraph", "data" => %{"text" => text}}) do
        "<p>#{text}</p>"
      end
    end
  end
end
