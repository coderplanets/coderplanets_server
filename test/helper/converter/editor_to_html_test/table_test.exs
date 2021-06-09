defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.Table do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHTML, as: Parser
  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Utils

  @root_class Class.article()
  @class get_in(@root_class, ["table"])

  describe "[table block unit]" do
    defp set_items(column_count, items, id \\ "") do
      %{
        "time" => 1_567_250_876_713,
        "blocks" => [
          %{
            "id" => id,
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

      assert Utils.str_occurence(converted, "id=") == 1

      assert Utils.str_occurence(converted, @class["th_header"]) == 4
      assert Utils.str_occurence(converted, @class["td_stripe"]) == 3
    end

    test "edit exsit block will not change id value" do
      editor_json =
        set_items(
          4,
          [
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
            }
          ],
          "block-id-exist"
        )

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, ~s(id="block-id-exist")) == 1
    end

    test "invalid table field parse should raise error message" do
      editor_json = set_items("aa", "bb")
      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, err_msg} = Parser.to_html(editor_string)

      assert err_msg == [
               %{
                 block: "table",
                 field: "columnCount",
                 message: "should be: number",
                 value: "aa"
               },
               %{block: "table", field: "items", message: "should be: list", value: "bb"}
             ]

      editor_json = set_items(-2, "bb")
      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, err_msg} = Parser.to_html(editor_string)

      assert err_msg == [
               %{block: "table", field: "columnCount", message: "min size: 2", value: -2},
               %{block: "table", field: "items", message: "should be: list", value: "bb"}
             ]
    end
  end
end
