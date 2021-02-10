defmodule Helper.Converter.EditorToHtml.Paragraph do
  @moduledoc """
  parse editor.js's json data to raw html and sanitize it

  see https://editorjs.io/
  """

  require Helper.Converter.EditorToHTML.ErrorHint, as: ErrorHint
  import Helper.Converter.EditorGuards

  # alias Helper.Metric
  # @clazz Metric.Article.class_names(:html)

  defmacro parse_block do
    quote do
      defp parse_block(%{"type" => "paragraph", "data" => %{"text" => text}})
           when is_valid_paragraph(text) do
        "<p>#{text}</p>"
      end

      ErrorHint.watch("paragraph", "text")
    end
  end
end
