defmodule GroupherServer.Test.Helper.Converter.Article do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.{Article, EditorToHTML}

  describe "[snaitizer test]" do
    test "parse_body should return valid format" do
      body = """
      {
        "time": 11,
        "blocks": [
          {
            "id" : "FLHF-eF_x4",
            "type" : "paragraph",
            "data" : {
              "text" : "this is a paragraph."
            }
          }
        ],
        "version": "2.20"
      }
      """

      {:ok, %{body: body, body_html: body_html}} = Article.parse_body(body)
      {:ok, body_map} = Jason.decode(body)

      assert body_html |> String.contains?("<p id=\"block-")

      p_block = body_map["blocks"] |> List.first()

      assert EditorToHTML.Validator.is_valid(body_map)
      assert p_block["id"] |> String.starts_with?("block-")
    end
  end
end
