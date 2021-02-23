defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.Table do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHTML, as: Parser
  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Utils

  @root_class Class.article()
  @class get_in(@root_class, ["list"])

  describe "[table block unit]" do
    defp set_items(column_count, items) do
      editor_json = %{
        "time" => 1_567_250_876_713,
        "blocks" => [
          %{
            "type" => "table",
            "data" => %{
              "columnCount" => column_count,
              "items" => items
            }
          }
        ],
        "version" => "2.15.0"
      }
    end

    @tag :wip2
    test "basic table parse should work" do
      editor_json =
        set_items(4, [
          %{
            "align" => "left",
            "isHeader" => true,
            "isStripe" => false,
            "text" => "title 0"
          },
          %{
            "align" => "center",
            "isHeader" => true,
            "isStripe" => false,
            "text" => "title 1",
            "width" => "180px"
          },
          %{
            "align" => "right",
            "isHeader" => true,
            "isStripe" => false,
            "text" => "title 2"
          },
          %{
            "align" => "left",
            "isHeader" => true,
            "isStripe" => false,
            "text" => "title 3"
          },
          %{
            "align" => "left",
            "isStripe" => false,
            "text" => "cell 0"
          },
          %{
            "align" => "center",
            "isStripe" => false,
            "text" => "cell 1",
            "width" => "180px"
          },
          %{
            "align" => "right",
            "isStripe" => false,
            "text" => "cell 2"
          },
          %{
            "align" => "left",
            "isStripe" => false,
            "text" => "cell 3"
          },
          %{
            "align" => "left",
            "isStripe" => true,
            "text" => "cell 4"
          },
          %{
            "align" => "left",
            "isStripe" => true,
            "text" => "cell 5"
          },
          %{
            "align" => "left",
            "isStripe" => true,
            "text" => ""
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      IO.inspect(converted, label: "table >>")

      # unorder_list_prefix_class = @class["unorder_list_prefix"]
      # assert Utils.str_occurence(converted, unorder_list_prefix_class) == 3
    end

    # @tag :wip
    # test "invalid list mode parse should raise error message" do
    #   editor_json = set_items("invalid-mode", [])
    #   {:ok, editor_string} = Jason.encode(editor_json)
    #   {:error, err_msg} = Parser.to_html(editor_string)

    #   assert err_msg == [
    #            %{
    #              block: "list",
    #              field: "mode",
    #              message: "should be: checklist | order_list | unorder_list"
    #            }
    #          ]
    # end
  end
end
