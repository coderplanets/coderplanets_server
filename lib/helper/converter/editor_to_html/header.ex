defmodule Helper.Converter.EditorToHTML.Header do
  @moduledoc """
  parse editor.js's header block

  see https://editorjs.io/
  """

  # @behaviour Helper.Converter.EditorToHTML.Parser

  defmacro __using__(_opts) do
    quote do
      alias Helper.Converter.EditorToHTML.{Class, Frags}

      @class get_in(Class.article(), ["header"])

      defp parse_block(%{"type" => "header", "data" => data}) do
        Frags.Header.get(data)
      end
    end
  end
end
