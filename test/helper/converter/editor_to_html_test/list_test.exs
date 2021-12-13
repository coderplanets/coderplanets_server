defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.List do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHTML, as: Parser
  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Utils

  @root_class Class.article()
  @class get_in(@root_class, ["list"])

  describe "[list block unit]" do
    defp set_items(mode, items, id \\ "") do
      %{
        "time" => 1_567_250_876_713,
        "blocks" => [
          %{
            "id" => id,
            "type" => "list",
            "data" => %{
              "mode" => mode,
              "items" => items
            }
          }
        ],
        "version" => "2.15.0"
      }
    end

    test "basic list parse should work" do
      editor_json =
        set_items("unordered_list", [
          %{
            "checked" => true,
            "hideLabel" => false,
            "indent" => 0,
            "label" => "label",
            "labelType" => "default",
            "text" =>
              "一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。"
          },
          %{
            "checked" => false,
            "hideLabel" => false,
            "indent" => 0,
            "label" => "label",
            "labelType" => "default",
            "text" => "list item"
          },
          %{
            "checked" => false,
            "hideLabel" => false,
            "indent" => 1,
            "label" => "green",
            "labelType" => "green",
            "text" => "list item"
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, @class["unordered_list_prefix"]) == 3
    end

    test "basic order list parse should work" do
      editor_json =
        set_items("order_list", [
          %{
            "checked" => true,
            "hideLabel" => false,
            "indent" => 0,
            "label" => "label",
            "labelType" => "default",
            "prefixIndex" => "1.",
            "text" =>
              "一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。"
          },
          %{
            "checked" => false,
            "hideLabel" => false,
            "indent" => 0,
            "label" => "label",
            "labelType" => "default",
            "prefixIndex" => "2.",
            "text" => "list item"
          },
          %{
            "checked" => false,
            "hideLabel" => false,
            "indent" => 1,
            "label" => "green",
            "labelType" => "green",
            "prefixIndex" => "2.1",
            "text" => "list item"
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, "id=") == 1

      assert Utils.str_occurence(converted, @class["order_list_prefix"]) == 3
    end

    test "edit exsit block will not change id value" do
      editor_json =
        set_items(
          "order_list",
          [
            %{
              "checked" => true,
              "hideLabel" => false,
              "indent" => 0,
              "label" => "label",
              "labelType" => "default",
              "prefixIndex" => "1.",
              "text" =>
                "一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。"
            }
          ],
          "block-id-exist"
        )

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, ~s(id="block-id-exist")) == 1
    end

    test "basic checklist parse should work" do
      editor_json =
        set_items("checklist", [
          %{
            "checked" => true,
            "hideLabel" => false,
            "indent" => 0,
            "label" => "label",
            "labelType" => "default",
            "text" =>
              "一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。"
          },
          %{
            "checked" => false,
            "hideLabel" => false,
            "indent" => 0,
            "label" => "label",
            "labelType" => "default",
            "text" => "list item"
          },
          %{
            "checked" => false,
            "hideLabel" => false,
            "indent" => 1,
            "label" => "green",
            "labelType" => "green",
            "text" => "list item"
          },
          %{
            "checked" => false,
            "hideLabel" => false,
            "indent" => 1,
            "label" => "red",
            "labelType" => "red",
            "text" => "list item"
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, @class["checklist_checkbox_checked"]) == 1
    end

    test "checklist without label parse should work" do
      editor_json =
        set_items("checklist", [
          %{
            "checked" => true,
            "hideLabel" => true,
            "indent" => 0,
            "label" => "label",
            "labelType" => "default",
            "text" => "list item"
          },
          %{
            "checked" => false,
            "hideLabel" => true,
            "indent" => 0,
            "label" => "label",
            "labelType" => "default",
            "text" => "list item"
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, @class["label"]) == 0
    end

    test "invalid list mode parse should raise error message" do
      editor_json = set_items("invalid-mode", [])
      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, err_msg} = Parser.to_html(editor_string)

      assert [
               %{block: "list", field: "items", message: "empty is not allowed", value: []},
               %{
                 block: "list",
                 field: "mode",
                 message: "should be: checklist | order_list | unordered_list"
               }
             ] == err_msg
    end

    test "invalid list data parse should raise error message" do
      editor_json =
        set_items("checklist", [
          %{
            "checked" => true,
            "hideLabel" => "invalid",
            "indent" => 5,
            "label" => "label",
            "labelType" => "default",
            "text" => "list item"
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
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
                 message: "should be: 0 | 1 | 2 | 3"
               }
             ]
    end

    test "invalid indent field should get error" do
      editor_json =
        set_items("checklist", [
          %{
            "checked" => true,
            "hideLabel" => true,
            "indent" => 10,
            "label" => "label",
            "labelType" => "default",
            "text" => "list item"
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, error} = Parser.to_html(editor_string)

      assert error === [
               %{
                 block: "list(checklist)",
                 field: "indent",
                 message: "should be: 0 | 1 | 2 | 3"
               }
             ]
    end
  end
end
