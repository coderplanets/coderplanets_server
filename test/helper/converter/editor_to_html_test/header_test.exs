defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.Header do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Metric
  alias Helper.Converter.EditorToHTML, as: Parser

  @clazz Metric.Article.class_names(:html)

  describe "[header block unit]" do
    @editor_json %{
      "time" => 1_567_250_876_713,
      "blocks" => [
        %{
          "type" => "header",
          "data" => %{
            "text" => "header content",
            "level" => 1
          }
        },
        %{
          "type" => "header",
          "data" => %{
            "text" => "header content",
            "level" => 2
          }
        },
        %{
          "type" => "header",
          "data" => %{
            "text" => "header content",
            "level" => 3
          }
        }
      ],
      "version" => "2.15.0"
    }
    @tag :wip
    test "header parse should work" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert converted ==
               "<div class=\"#{@clazz.viewer}\"><h1>header content</h1><h2>header content</h2><h3>header content</h3><div>"
    end

    @editor_json %{
      "time" => 1_567_250_876_713,
      "blocks" => [
        %{
          "type" => "header",
          "data" => %{
            "text" => "header content",
            "level" => 1,
            "eyebrowTitle" => "eyebrow title content",
            "footerTitle" => "footer title content"
          }
        }
      ],
      "version" => "2.15.0"
    }
    @tag :wip
    test "full header parse should work" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert converted ==
               "<div class=\"#{@clazz.viewer}\"><div class=\"#{@clazz.header.wrapper}\">\n  <div class=\"#{
                 @clazz.header.eyebrow_title
               }\">eyebrow title content</div>\n  <h1>header content</h1>\n  <div class=\"#{
                 @clazz.header.footer_title
               }\">footer title content</div>\n</div>\n<div>"
    end

    @editor_json %{
      "time" => 1_567_250_876_713,
      "version" => "2.15.0"
    }
    @tag :wip
    test "wrong header format data should have invalid hint" do
      json =
        Map.merge(@editor_json, %{
          "blocks" => [
            %{
              "type" => "header",
              "data" => %{
                "text" => "header content",
                "level" => 1,
                "eyebrowTitle" => []
              }
            }
          ]
        })

      {:ok, editor_string} = Jason.encode(json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert converted ==
               "<div class=\"#{@clazz.viewer}\"><div class=\"#{@clazz.invalid_block}\">[invalid-block] header:eyebrowTitle</div><div>"

      json =
        Map.merge(@editor_json, %{
          "blocks" => [
            %{
              "type" => "header",
              "data" => %{
                "text" => "header content",
                "level" => 1,
                "footerTitle" => []
              }
            }
          ]
        })

      {:ok, editor_string} = Jason.encode(json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert converted ==
               "<div class=\"#{@clazz.viewer}\"><div class=\"#{@clazz.invalid_block}\">[invalid-block] header:footerTitle</div><div>"

      json =
        Map.merge(@editor_json, %{
          "blocks" => [
            %{
              "type" => "header",
              "data" => %{
                "text" => "header content",
                "level" => []
              }
            }
          ]
        })

      {:ok, editor_string} = Jason.encode(json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert converted ==
               "<div class=\"#{@clazz.viewer}\"><div class=\"#{@clazz.invalid_block}\">[invalid-block] header:text or level</div><div>"
    end
  end
end
