defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.Paragraph do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Metric
  alias Helper.Converter.EditorToHTML, as: Parser

  @clazz Metric.Article.class_names(:html)

  describe "[paragraph block]" do
    @editor_json %{
      "time" => 1_567_250_876_713,
      "blocks" => [
        %{
          "type" => "paragraph",
          "data" => %{
            "text" => "paragraph content"
          }
        }
      ],
      "version" => "2.15.0"
    }
    @tag :wip
    test "paragraph parse should work" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert converted == "<div class=\"#{@clazz.viewer}\"><p>paragraph content</p><div>"
    end

    @editor_json %{
      "time" => 1_567_250_876_713,
      "blocks" => [
        %{
          "type" => "paragraph",
          "data" => %{
            "text" => []
          }
        }
      ],
      "version" => "2.15.0"
    }
    @tag :wip
    test "invalid paragraph should have invalid hint" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert converted ==
               "<div class=\"#{@clazz.viewer}\"><div class=\"#{@clazz.invalid_block}\">[invalid-block] paragraph:text</div><div>"
    end
  end
end
