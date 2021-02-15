defmodule Helper.Converter.EditorToHTML.List do
  @moduledoc """
  parse editor.js's list-like block (include checklist order/unorder list)

  see https://editorjs.io/
  """

  # @behaviour Helper.Converter.EditorToHTML.Parser

  defmacro __using__(_opts) do
    quote do
      alias Helper.Metric

      @clazz Metric.Article.class_names(:html)

      defp parse_block(%{
             "type" => "list",
             "data" =>
               %{
                 "mode" => "checklist",
                 "items" => [
                   %{
                     "checked" => checked,
                     "hideLabel" => hide_label,
                     "indent" => indent,
                     "label" => label,
                     "labelType" => label_type,
                     "text" => text
                   }
                 ]
               } = data
           }) do
        """
        <div class="#{@clazz.list.wrapper}">
        hello list
        </div>
        """

        # <div class="#{@clazz.list.wrapper}">
        #   <div class="#{@clazz.list.eyebrow_title}">#{eyebrow_title}</div>
        #   <h#{level}>#{text}</h#{level}>
        #   <div class="#{@clazz.list.footer_title}">#{footer_title}</div>
        # </div>
      end

      defp parse_block(%{
             "type" => "list",
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
             "type" => "list",
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
             "type" => "list",
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

# {
#   type: "list",
#   data: {
#     type: "checklist",
#     items: [
#       {
#         checked: true,
#         hideLabel: false,
#         indent: 0,
#         label: '标签',
#         labelType: 'default',
#         text: "content 1.",
#       },
#       {
#         checked: false,
#         hideLabel: false,
#         indent: 1,
#         label: '完成',
#         labelType: 'green',
#         text: "content 1.1",
#       },
#       {
#         checked: false,
#         hideLabel: false,
#         indent: 1,
#         label: '未完成',
#         labelType: 'red',
#         text: "content 1.2",
#       },
#       {
#         checked: false,
#         hideLabel: false,
#         indent: 0,
#         label: '完成',
#         labelType: 'green',
#         text: "content 2.",
#       },
#       {
#         checked: false,
#         hideLabel: false,
#         indent: 1,
#         label: '标签',
#         labelType: 'default',
#         text: "content 2.1",
#       },
#       {
#         checked: false,
#         hideLabel: false,
#         indent: 2,
#         label: '标签',
#         labelType: 'default',
#         text: "content 2.1.1",
#       },
#       {
#         checked: false,
#         hideLabel: false,
#         indent: 2,
#         label: '未完成',
#         labelType: 'red',
#         text: "content 2.1.2",
#       },
#       {
#         checked: false,
#         hideLabel: false,
#         indent: 3,
#         label: '未完成',
#         labelType: 'red',
#         text: "content 2.1.2.1",
#       },
#       {
#         checked: false,
#         hideLabel: false,
#         indent: 2,
#         label: '完成',
#         labelType: 'green',
#         text: "content 2.1.3",
#       },
#       {
#         checked: false,
#         hideLabel: false,
#         indent: 3,
#         label: '标签',
#         labelType: 'default',
#         text: "content 2.1.3.1",
#       },
#       {
#         checked: false,
#         hideLabel: false,
#         indent: 3,
#         label: '完成',
#         labelType: 'green',
#         text: "content 2.1.3.2",
#       },
#       {
#         checked: false,
#         hideLabel: false,
#         indent: 0,
#         label: '未完成',
#         labelType: 'red',
#         text: "content 3.",
#       },
#     ]
#   },
# }
