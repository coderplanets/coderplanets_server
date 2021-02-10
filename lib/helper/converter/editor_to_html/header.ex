defmodule Helper.Converter.EditorToHtml.Header do
  @moduledoc """
  parse editor.js's json data to raw html and sanitize it

  see https://editorjs.io/
  """
  require Helper.Converter.EditorToHTML.ErrorHint, as: ErrorHint

  import Helper.Converter.EditorGuards

  alias Helper.Converter.{EditorToHtml, HtmlSanitizer}
  alias Helper.{Metric, Utils}

  alias EditorToHtml.Assets.{DelimiterIcons}

  @clazz Metric.Article.class_names(:html)

  defmacro parse_block do
    quote do
      defp parse_block(%{
             "type" => "header",
             "data" =>
               %{
                 "text" => text,
                 "level" => level,
                 "eyebrowTitle" => eyebrow_title,
                 "footerTitle" => footer_title
               } = data
           })
           when is_valid_header(text, level, eyebrow_title, footer_title) do
        """
        <div class="#{@clazz.header.wrapper}">
          <div class="#{@clazz.header.eyebrow_title}">#{eyebrow_title}</div>
          <h#{level}>#{text}</h#{level}>
          <div class="#{@clazz.header.footer_title}">#{footer_title}</div>
        </div>
        """
      end

      defp parse_block(%{
             "type" => "header",
             "data" =>
               %{
                 "text" => text,
                 "level" => level,
                 "eyebrowTitle" => eyebrow_title
               } = data
           })
           when is_valid_header(text, level, eyebrow_title) do
        """
        <div class="#{@clazz.header.wrapper}">
          <div class="#{@clazz.header.eyebrow_title}">#{eyebrow_title}</div>
          <h#{level}>#{text}</h#{level}>
        </div>
        """
      end

      ErrorHint.watch("header", "eyebrowTitle")

      defp parse_block(%{
             "type" => "header",
             "data" =>
               %{
                 "text" => text,
                 "level" => level,
                 "footerTitle" => footer_title
               } = data
           })
           when is_valid_header(text, level, footer_title) do
        """
        <div class="#{@clazz.header.wrapper}">
          <h#{level}>#{text}</h#{level}>
          <div class="#{@clazz.header.footer_title}">#{footer_title}</div>
        </div>
        """
      end

      ErrorHint.watch("header", "footerTitle")

      defp parse_block(%{
             "type" => "header",
             "data" => %{
               "text" => text,
               "level" => level
             }
           })
           when is_valid_header(text, level) do
        "<h#{level}>#{text}</h#{level}>"
      end

      ErrorHint.watch("header", "text", "level")
    end
  end
end
