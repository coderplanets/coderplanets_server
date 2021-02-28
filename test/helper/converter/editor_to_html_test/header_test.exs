defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.Header do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHTML, as: Parser
  alias Helper.Converter.EditorToHTML.{Class, Frags}
  alias Helper.Utils

  @root_class Class.article()
  @class get_in(@root_class, ["header"])

  @eyebrow_class @class["eyebrow_title"]
  @footer_class @class["footer_title"]

  describe "[header block unit]" do
    defp set_data(data) do
      %{
        "time" => 1_567_250_876_713,
        "blocks" => [
          %{
            "type" => "header",
            "data" => data
          }
        ],
        "version" => "2.15.0"
      }
    end

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

      h1_frag = Frags.Header.get(%{"text" => "header content", "level" => 1})
      h2_frag = Frags.Header.get(%{"text" => "header content", "level" => 2})
      h3_frag = Frags.Header.get(%{"text" => "header content", "level" => 3})

      viewer_class = @root_class["viewer"]

      assert converted ==
               ~s(<div class="#{viewer_class}">#{h1_frag}#{h2_frag}#{h3_frag}</div>)
    end

    @tag :wip2
    test "full header parse should work" do
      editor_json =
        set_data(%{
          "text" => "header content",
          "level" => 1,
          "eyebrowTitle" => "eyebrow title content",
          "footerTitle" => "footer title content"
        })

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      # header_class = @class["header"]
      assert Utils.str_occurence(converted, "id=") == 1
      # assert Utils.str_occurence(converted, header_class) == 1
      assert Utils.str_occurence(converted, @eyebrow_class) == 1
      assert Utils.str_occurence(converted, @footer_class) == 1
    end

    @tag :wip2
    test "edit exsit block will not change id value" do
      editor_json =
        set_data(%{
          "id" => "exist",
          "text" => "header content",
          "level" => 1,
          "eyebrowTitle" => "eyebrow title content",
          "footerTitle" => "footer title content"
        })

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, ~s(id="exist")) == 1
    end

    @tag :wip2
    test "optional field should valid properly" do
      editor_json =
        set_data(%{
          "text" => "header content",
          "level" => 1,
          "eyebrowTitle" => "eyebrow title content"
        })

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, @eyebrow_class) == 1
      assert Utils.str_occurence(converted, @footer_class) == 0

      editor_json =
        set_data(%{
          "text" => "header content",
          "level" => 1,
          "footerTitle" => "footer title content"
        })

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, @eyebrow_class) == 0
      assert Utils.str_occurence(converted, @footer_class) == 1
    end

    @tag :wip2
    test "wrong header format data should have invalid hint" do
      editor_json =
        set_data(%{
          "text" => "header content",
          "level" => 1,
          "eyebrowTitle" => [],
          "footerTitle" => true
        })

      {:ok, editor_string} = Jason.encode(editor_json)
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

      editor_json =
        set_data(%{
          "text" => "header content",
          "level" => []
        })

      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, error} = Parser.to_html(editor_string)
      assert error == [%{block: "header", field: "level", message: "should be: 1 | 2 | 3"}]
    end
  end
end
