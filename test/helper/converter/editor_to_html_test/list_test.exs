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
    @tag :wip
    test "invalid list data parse should raise error message" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:error, err_msg} = Parser.to_html(editor_string)

      assert err_msg ==
               "indent should be: 0 | 1 | 2 | 3 | 4 ; hideLabel should be: boolean"
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
      # {:ok, converted} = Parser.to_html(editor_string)
      Parser.to_html(editor_string)

      assert {:ok, converted} = Parser.to_html(editor_string)
      # IO.inspect(converted, label: "->> converted")
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
      # {:ok, converted} = Parser.to_html(editor_string)
      assert {:error, "indent field should be: 0 | 1 | 2 | 3 | 4"} = Parser.to_html(editor_string)
    end
  end
end
