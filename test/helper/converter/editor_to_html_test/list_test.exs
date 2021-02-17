defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.List do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Metric
  alias Helper.Converter.EditorToHTML, as: Parser

  @clazz Metric.Article.class_names(:html)

  describe "[list block unit]" do
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
                "hideLabel" => false,
                "indent" => 0,
                "label" => "label",
                "labelType" => "success",
                "text" => "list item"
              }
            ]
          }
        }
      ],
      "version" => "2.15.0"
    }
    @tag :wip
    test "valid list parse should work" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      # assert {:ok, converted} = Parser.to_html(editor_string)
      {:ok, converted} = Parser.to_html(editor_string)
      IO.inspect(converted, label: "list converted")
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
                "labelType" => "success",
                "text" => "list item"
              }
            ]
          }
        }
      ],
      "version" => "2.15.0"
    }
    @tag :wip2
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
                "labelType" => "success",
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
