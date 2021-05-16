defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.People do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true
  import GroupherServer.Support.Factory

  alias Helper.Converter.EditorToHTML, as: Parser
  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Utils

  @root_class Class.article()
  @class get_in(@root_class, ["people"])

  describe "[people block unit]" do
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

    test "multi people should have previewer" do
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
                "name" => "github",
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

      assert Utils.str_occurence(converted, @class["gallery_previewer_wrapper"]) == 1
      assert Utils.str_occurence(converted, @class["gallery_previewer_item"]) == 3
      assert Utils.str_occurence(converted, @class["gallery_previewer_active_item"]) == 1
      assert Utils.str_occurence(converted, @class["gallery_card_wrapper"]) == 2

      assert Utils.str_occurence(converted, mock_image()) == 4
    end

    test "one people should not have previewer bar" do
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
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, @class["gallery_previewer_wrapper"]) == 0
      assert Utils.str_occurence(converted, @class["gallery_card_wrapper"]) == 1
      assert Utils.str_occurence(converted, @class["gallery_avatar"]) == 1

      assert Utils.str_occurence(converted, @class["gallery_intro_title"]) == 1
      assert Utils.str_occurence(converted, @class["gallery_intro_bio"]) == 1
      assert Utils.str_occurence(converted, @class["gallery_intro_desc"]) == 1

      assert Utils.str_occurence(converted, @class["gallery_social_icon"]) == 2

      assert Utils.str_occurence(converted, mock_image()) == 1
    end
  end
end
