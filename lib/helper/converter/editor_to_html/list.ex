defmodule Helper.Converter.EditorToHTML.List do
  @moduledoc """
  parse editor.js's list-like block (include checklist order/unorder list)

  see https://editorjs.io/
  """

  # @behaviour Helper.Converter.EditorToHTML.Parser

  defmacro __using__(_opts) do
    quote do
      alias Helper.Metric
      alias Helper.Converter.EditorToHTML.Frags

      # @class get_in(Metric.Article.class_names(:html), "list")

      defp parse_block(%{"type" => "list", "data" => data}) do
        %{"items" => items} = data

        Frags.List.get_item(:checklist, Enum.at(items, 0))
      end

      # defp parse_block(%{"type" => "list", "data" => %{"style" => "ordered", "items" => items}}) do
      #   content =
      #     Enum.reduce(items, "", fn item, acc ->
      #       acc <> "<li>#{item}</li>"
      #     end)

      #   "<ol>#{content}</ol>"
      # end
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
