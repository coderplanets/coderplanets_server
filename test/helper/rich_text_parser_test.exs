defmodule GroupherServer.Test.Helper.RichTextParserTest do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.RichTextParser, as: Parser

  describe "[basic convert]" do
    @tag :wip2
    test "string_to_json should work" do
      string = ~s({"time":1566184478687,"blocks":[{}],"version":"2.15.0"})
      hello = Parser.string_to_json(string)

      IO.inspect(hello, label: "hello")
    end

    test "TODO:  test emoji. 😏" do
      true
    end

    @tag :wip2
    test "real data should work" do
      editor_json2 = ~S({
        "time": 1563816717958,
        "blocks": [{
            "type": "header",
            "data": {
              "text": "(Editor.js\)",
              "level": 2
            }
          }
        ],
        "version": "2.15.0"
      })

      editor_json = """
      {
        "time": 1563816717958,
        "blocks": [{
            "type": "header",
            "data": {
              "text": "(Editor.js)",
              "level": 2
            }
          }
        ],
        "version": "2.15.0"
      }
      """

      hello = Jason.decode!(editor_json)
      IO.inspect(hello, label: "hello")
    end
  end
end
