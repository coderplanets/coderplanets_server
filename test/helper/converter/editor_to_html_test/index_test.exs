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
    test "basic string_json parse should work" do
      string = ~S({"time":1566184478687,"blocks":[{}],"version":"2.15.0"})
      {:ok, converted} = Parser.string_to_json(string)

      assert converted["version"] == "2.15.0"
    end

    @editor_json %{
      "time" => 1_567_250_876_713,
      "blocks" => [],
      "version" => "2.15.0"
    }
    @tag :wip
    test "valid editorjs json fmt should work" do
      {:ok, editor_string} = Jason.encode(@editor_json)

      assert {:ok, _} = Parser.to_html(editor_string)
    end

    @tag :wip2
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

    test "real-world editor.js data should work" do
      {:ok, converted} = Parser.string_to_json(@real_editor_data)

      assert not Enum.empty?(converted["blocks"])
      assert converted["blocks"] |> is_list
      assert converted["version"] |> is_binary
      assert converted["time"] |> is_integer
    end
  end

  describe "[secure issues]" do
    @tag :wip
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

      viewer_class = @root_class["viewer"]

      assert converted ==
               ~s(<div class="#{viewer_class}"><p>evel script</p></div>)

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

      viewer_class = @root_class["viewer"]

      assert converted ==
               ~s(<div class="#{viewer_class}"><p>Editor.js is an element &lt;script&gt;evel script&lt;/script&gt;</p></div>)
    end
  end
end
