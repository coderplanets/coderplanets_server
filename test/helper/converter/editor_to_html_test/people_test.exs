defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.People do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHTML, as: Parser
  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Utils

  alias Helper.Converter.EditorToHTML.Assets.SocialIcons

  @root_class Class.article()
  @class get_in(@root_class, ["people"])

  describe "[people block unit]" do
    defp mock_image() do
      "https://rmt.dogedoge.com/fetch/~/source/unsplash/photo-1557555187-23d685287bc3?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80"
    end

    defp set_items(mode, items, id \\ "") do
      %{
        "time" => 1_567_250_876_713,
        "blocks" => [
          %{
            "type" => "people",
            "data" => %{
              "id" => id,
              "mode" => mode,
              "items" => items
            }
          }
        ],
        "version" => "2.15.0"
      }
    end

    @tag :wip2
    test "basic people parse should work" do
      editor_json =
        set_items("gallery", [
          %{
            "avatar" => mock_image(),
            "title" => "title",
            "bio" => "this is a X man",
            "desc" => "hello world i am x man",
            "socials" => [
              %{
                "name" => "zhihu",
                "link" => "https://link"
              },
              %{
                "name" => "twitter",
                "link" => "https://link"
              }
            ]
          },
          %{
            "avatar" => mock_image(),
            "title" => "title2",
            "bio" => "this is a X man2",
            "desc" => "hello world i am x man2",
            "socials" => [
              %{
                "name" => "zhihu",
                "link" => "https://link"
              },
              %{
                "name" => "twitter",
                "link" => "https://link"
              }
            ]
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      IO.inspect(converted, label: "people")

      # unorder_list_prefix_class = @class["unorder_list_prefix"]
      # assert Utils.str_occurence(converted, unorder_list_prefix_class) == 3
    end
  end
end
