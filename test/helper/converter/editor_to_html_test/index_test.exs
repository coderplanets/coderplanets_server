defmodule GroupherServer.Test.Helper.Converter.EditorToHTML do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Converter.EditorToHTML, as: Parser

  #   "<addr class="cdx-lock">hello</addr> Editor.js <mark class="cdx-marker">workspace</mark>. is an element &lt;script&gt;alert("hello")&lt;/script&gt;"

  #   "text" : "<script>evil scripts</script>"
  @root_class Class.article()

  @real_editor_data ~S({
    "time" : 1567250876713,
    "blocks" : [
        {
            "type" : "paragraph",
            "data" : {
                "text": "content"
            }
        }
    ],
    "version" : "2.15.0"
  })

  describe "[basic convert]" do
    @editor_json %{
      "time" => 1_567_250_876_713,
      "blocks" => [],
      "version" => "2.15.0"
    }

    test "valid editorjs json fmt should work" do
      {:ok, editor_string} = Jason.encode(@editor_json)

      assert {:ok, _} = Parser.to_html(editor_string)
    end

    test "invalid editorjs json fmt should raise error" do
      editor_json = %{
        "invalid_time" => 1_567_250_876_713,
        "blocks" => [],
        "version" => "2.15.0"
      }

      {:ok, editor_string} = Jason.encode(editor_json)

      {:error, error} = Parser.to_html(editor_string)

      assert error == [
               %{block: "editor", field: "time", message: "should be: number", value: nil}
             ]

      editor_json = %{
        "time" => "1_567_250_876_713",
        "blocks" => [],
        "version" => "2.15.0"
      }

      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, error} = Parser.to_html(editor_string)

      assert error == [
               %{
                 block: "editor",
                 field: "time",
                 message: "should be: number",
                 value: "1_567_250_876_713"
               }
             ]

      editor_json = %{
        "time" => 1_567_250_876_713,
        # invalid blocks type, should be list
        "blocks" => "blocks",
        "version" => "2.15.0"
      }

      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, error} = Parser.to_html(editor_string)

      assert error == [
               %{block: "editor", field: "blocks", message: "should be: list", value: "blocks"}
             ]

      editor_json = %{
        "time" => 1_567_250_876_713,
        "blocks" => [1, 2, 3],
        "version" => "2.15.0"
      }

      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, error} = Parser.to_html(editor_string)

      assert String.contains?(error, "undown block: 1")
    end
  end

  describe "[secure issues]" do
    test "code block should avoid potential xss script attack" do
      editor_json = %{
        "time" => 1_567_250_876_713,
        "blocks" => [
          %{
            "type" => "paragraph",
            "data" => %{
              "text" => "<script>evel script</script>"
            }
          }
        ],
        "version" => "2.15.0"
      }

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert converted |> String.contains?(~s(<div class="#{@root_class["viewer"]}">))
      assert converted |> String.contains?(~s(<p id="block-))

      editor_json = %{
        "time" => 1_567_250_876_713,
        "blocks" => [
          %{
            "type" => "paragraph",
            "data" => %{
              "text" => "Editor.js is an element &lt;script&gt;evel script&lt;/script&gt;"
            }
          }
        ],
        "version" => "2.15.0"
      }

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert converted |> String.contains?(~s(<div class="#{@root_class["viewer"]}">))

      assert converted
             |> String.contains?(
               ~s(Editor.js is an element &lt;script&gt;evel script&lt;/script&gt;)
             )
    end
  end
end
