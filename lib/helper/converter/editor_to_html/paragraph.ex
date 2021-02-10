defmodule Helper.Converter.EditorToHTML.Paragraph do
  @moduledoc """
  parse editor.js's paragraph block

  see https://editorjs.io/
  """
  defmacro __using__(_opts) do
    quote do
      require Helper.Converter.EditorToHTML.ErrorHint, as: ErrorHint
      import Helper.Converter.EditorToHTML.Guards

      # alias Helper.Metric
      # @clazz Metric.Article.class_names(:html)

      defp parse_block(%{"type" => "paragraph", "data" => %{"text" => text}})
           when is_valid_paragraph(text) do
        "<p>#{text}</p>"
      end

      ErrorHint.watch("paragraph", "text")
    end
  end
end
