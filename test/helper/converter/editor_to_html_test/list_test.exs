defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.List do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHTML, as: Parser
  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Utils

  @root_class Class.article()
  @class get_in(@root_class, ["list"])

  describe "[list block unit]" do
    @items [
      %{
        "checked" => true,
        "hideLabel" => false,
        "indent" => 0,
        "label" => "label",
        "labelType" => "default",
        "text" => "list item"
      },
      %{
        "checked" => false,
        "hideLabel" => false,
        "indent" => 0,
        "label" => "label",
        "labelType" => "default",
        "text" => "list item"
      }
    ]
    @editor_json %{
      "time" => 1_567_250_876_713,
      "blocks" => [
        %{
          "type" => "list",
          "data" => %{
            "mode" => "checklist",
            "items" => @items
          }
        }
      ],
      "version" => "2.15.0"
    }
    @tag :wip2
    test "valid list parse should work" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      IO.inspect(converted, label: "the converted")

      checked_class = @class["checklist_checkbox_checked"]

      assert Utils.str_occurence(converted, checked_class) == 1
    end

    @editor_json %{
      "time" => 1_567_250_876_713,
      "blocks" => [
        %{
          "type" => "list",
          "data" => %{
            "invalid-mode" => "",
            "items" => []
          }
        }
      ],
      "version" => "2.15.0"
    }
    @tag :wip
    test "invalid list mode parse should raise error message" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:error, err_msg} = Parser.to_html(editor_string)

      assert err_msg == [
               %{
                 block: "list",
                 field: "mode",
                 message: "should be: checklist | order_list | unorder_list"
               }
             ]
    end

    @editor_json %{
      "time" => 1_567_250_876_713,
      "blocks" => [
        %{
          "type" => "list",
          "data" => %{
            "mode" => "checklist",
            "items" => [
              %{
                "checked" => true,
                "hideLabel" => "invalid",
                "indent" => 5,
                "label" => "label",
                "labelType" => "default",
                "text" => "list item"
              }
            ]
          }
        }
      ],
      "version" => "2.15.0"
    }
    @tag :wip
    test "invalid list data parse should raise error message" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:error, err_msg} = Parser.to_html(editor_string)

      assert err_msg == [
               %{
                 block: "list(checklist)",
                 field: "hideLabel",
                 message: "should be: boolean",
                 value: "invalid"
               },
               %{
                 block: "list(checklist)",
                 field: "indent",
                 message: "should be: 0 | 1 | 2 | 3 | 4"
               }
             ]
    end

    @editor_json %{
      "time" => 1_567_250_876_713,
      "blocks" => [
        %{
          "type" => "list",
          "data" => %{
            "mode" => "checklist",
            "items" => [
              %{
                "checked" => true,
                "hideLabel" => true,
                "indent" => 10,
                "label" => "label",
                "labelType" => "default",
                "text" => "list item"
              }
            ]
          }
        }
      ],
      "version" => "2.15.0"
    }
    @tag :wip
    test "invalid indent field should get error" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:error, error} = Parser.to_html(editor_string)

      assert error === [
               %{
                 block: "list(checklist)",
                 field: "indent",
                 message: "should be: 0 | 1 | 2 | 3 | 4"
               }
             ]
    end
  end
end
