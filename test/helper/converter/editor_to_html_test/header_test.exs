defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.Header do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHTML, as: Parser
  alias Helper.Converter.EditorToHTML.{Class, Frags}

  @root_class Class.article()

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
    @tag :wip2
    test "header parse should work" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      h1_frag = Frags.Header.get(%{"text" => "header content", "level" => 1})
      h2_frag = Frags.Header.get(%{"text" => "header content", "level" => 2})
      h3_frag = Frags.Header.get(%{"text" => "header content", "level" => 3})

      viewer_class = @root_class["viewer"]

      assert converted ==
               ~s(<div class="#{viewer_class}">#{h1_frag}#{h2_frag}#{h3_frag}</div>)
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
    @tag :wip2
    test "full header parse should work" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      frag =
        Frags.Header.get(%{
          "text" => "header content",
          "level" => 1,
          "eyebrowTitle" => "eyebrow title content",
          "footerTitle" => "footer title content"
        })

      viewer_class = @root_class["viewer"]

      assert converted ==
               ~s(<div class="#{viewer_class}">#{frag}</div>)
    end

    @editor_json %{
      "time" => 1_567_250_876_713,
      "version" => "2.15.0"
    }
    @tag :wip2
    test "optional field should valid properly" do
      json =
        Map.merge(@editor_json, %{
          "blocks" => [
            %{
              "type" => "header",
              "data" => %{
                "text" => "header content",
                "level" => 1,
                "eyebrowTitle" => "eyebrow title content"
              }
            }
          ]
        })

      {:ok, editor_string} = Jason.encode(json)
      {:ok, converted} = Parser.to_html(editor_string)

      frag =
        Frags.Header.get(%{
          "text" => "header content",
          "level" => 1,
          "eyebrowTitle" => "eyebrow title content"
        })

      viewer_class = @root_class["viewer"]

      assert converted ==
               ~s(<div class="#{viewer_class}">#{frag}</div>)

      json =
        Map.merge(@editor_json, %{
          "blocks" => [
            %{
              "type" => "header",
              "data" => %{
                "text" => "header content",
                "level" => 1,
                "footerTitle" => "footer title content"
              }
            }
          ]
        })

      {:ok, editor_string} = Jason.encode(json)
      {:ok, converted} = Parser.to_html(editor_string)

      frag =
        Frags.Header.get(%{
          "text" => "header content",
          "level" => 1,
          "footerTitle" => "footer title content"
        })

      viewer_class = @root_class["viewer"]

      assert converted ==
               ~s(<div class="#{viewer_class}">#{frag}</div>)
    end

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
                "eyebrowTitle" => [],
                "footerTitle" => true
              }
            }
          ]
        })

      {:ok, editor_string} = Jason.encode(json)
      {:error, error} = Parser.to_html(editor_string)

      assert error ==
               [
                 %{
                   block: "header",
                   field: "eyebrowTitle",
                   message: "should be: string",
                   value: []
                 },
                 %{
                   block: "header",
                   field: "footerTitle",
                   message: "should be: string",
                   value: true
                 }
               ]

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
      {:error, error} = Parser.to_html(editor_string)
      assert error == [%{block: "header", field: "level", message: "should be: 1 | 2 | 3"}]
    end
  end
end
