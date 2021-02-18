defmodule Helper.Converter.EditorToHTML.Header do
  @moduledoc """
  parse editor.js's header block

  see https://editorjs.io/
  """

  # @behaviour Helper.Converter.EditorToHTML.Parser

  defmacro __using__(_opts) do
    quote do
      alias Helper.Metric

      @clazz Metric.Article.class_names(:html)

      defp parse_block(%{
             "type" => "header",
             "data" =>
               %{
                 "text" => text,
                 "level" => level,
                 "eyebrowTitle" => eyebrow_title,
                 "footerTitle" => footer_title
               } = data
           }) do
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
           }) do
        """
        <div class="#{@clazz.header.wrapper}">
          <div class="#{@clazz.header.eyebrow_title}">#{eyebrow_title}</div>
          <h#{level}>#{text}</h#{level}>
        </div>
        """
      end

      defp parse_block(%{
             "type" => "header",
             "data" =>
               %{
                 "text" => text,
                 "level" => level,
                 "footerTitle" => footer_title
               } = data
           }) do
        """
        <div class="#{@clazz.header.wrapper}">
          <h#{level}>#{text}</h#{level}>
          <div class="#{@clazz.header.footer_title}">#{footer_title}</div>
        </div>
        """
      end

      defp parse_block(%{
             "type" => "header",
             "data" => %{
               "text" => text,
               "level" => level
             }
           }) do
        "<h#{level}>#{text}</h#{level}>"
      end
    end
  end
end
