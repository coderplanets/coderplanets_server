defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.Header do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHTML, as: Parser
  alias Helper.Converter.EditorToHTML.Class
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
            "text" => "header1 content",
            "level" => 1
          }
        },
        %{
          "type" => "header",
          "data" => %{
            "text" => "header2 content",
            "level" => 2
          }
        },
        %{
          "type" => "header",
          "data" => %{
            "text" => "header3 content",
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

      assert Utils.str_occurence(converted, "header1 content") == 1
      assert Utils.str_occurence(converted, "header2 content") == 1
      assert Utils.str_occurence(converted, "header3 content") == 1
    end

    @tag :wip
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

    @tag :wip
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

    @tag :wip
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

    @tag :wip
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
