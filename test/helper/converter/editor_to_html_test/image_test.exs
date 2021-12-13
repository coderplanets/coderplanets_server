defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.Image do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true
  import GroupherServer.Support.Factory

  alias Helper.Converter.EditorToHTML, as: Parser
  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Utils

  @root_class Class.article()
  @class get_in(@root_class, ["image"])

  describe "[image block unit]" do
    defp set_items(mode, items, id \\ "") do
      %{
        "time" => 1_567_250_876_713,
        "blocks" => [
          %{
            "id" => id,
            "type" => "image",
            "data" => %{
              "mode" => mode,
              "items" => items
            }
          }
        ],
        "version" => "2.15.0"
      }
    end

    test "single image parse should work" do
      editor_json =
        set_items("single", [
          %{
            "index" => 0,
            "src" => mock_image(),
            "caption" => "this is a caption",
            "width" => "368px",
            "height" => "552px"
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, "<img") == 1
      assert Utils.str_occurence(converted, "width:368px") == 1
      assert Utils.str_occurence(converted, "height:552px") == 1

      single_image_wrapper_class = @class["single_image_wrapper"]
      assert Utils.str_occurence(converted, single_image_wrapper_class) == 1

      image_caption_class = @class["image_caption"]
      assert Utils.str_occurence(converted, image_caption_class) == 1
      # one for display otherone is used in lightbox
      assert Utils.str_occurence(converted, "this is a caption") == 2
    end

    test "single image parse should work without wight && height" do
      editor_json =
        set_items("single", [
          %{
            "index" => 0,
            "src" => mock_image(),
            "caption" => "this is a caption"
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      # unordered_list_prefix_class = @class["unordered_list_prefix"]
      assert Utils.str_occurence(converted, "<img") == 1
      assert Utils.str_occurence(converted, "width:") == 0
      assert Utils.str_occurence(converted, "height:") == 0

      single_image_wrapper_class = @class["single_image_wrapper"]
      assert Utils.str_occurence(converted, single_image_wrapper_class) == 1
    end

    test "single image parse should work without caption" do
      editor_json =
        set_items("single", [
          %{
            "index" => 0,
            "src" => mock_image()
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      # unordered_list_prefix_class = @class["unordered_list_prefix"]
      assert Utils.str_occurence(converted, "<img") == 1
      assert Utils.str_occurence(converted, "width:") == 0
      assert Utils.str_occurence(converted, "height:") == 0

      single_image_wrapper_class = @class["single_image_wrapper"]
      assert Utils.str_occurence(converted, single_image_wrapper_class) == 1

      image_caption_class = @class["image_caption"]
      assert Utils.str_occurence(converted, image_caption_class) == 0
    end

    test "jiugongge image parse should work" do
      editor_json =
        set_items(
          "jiugongge",
          mock_images(9)
          |> Enum.with_index()
          |> Enum.map(fn {src, index} ->
            %{
              "index" => index,
              "src" => src,
              "caption" => "this is a caption 1"
            }
          end)
        )

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      jiugongge_image_wrapper_class = @class["jiugongge_image_wrapper"]
      jiugongge_image_class = @class["jiugongge_image"]

      assert Utils.str_occurence(converted, jiugongge_image_wrapper_class) == 1
      assert Utils.str_occurence(converted, jiugongge_image_class) == length(mock_images(9))
    end

    test "gallery image parse should work" do
      editor_json =
        set_items(
          "gallery",
          mock_images(9)
          |> Enum.with_index()
          |> Enum.map(fn {src, index} ->
            %{
              "index" => index,
              "src" => src,
              "caption" => "this is a caption 1"
            }
          end)
        )

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      gallery_image_class = @class["gallery_image"]
      gallery_mini_image_class = @class["gallery_image"]

      assert Utils.str_occurence(converted, gallery_image_class) == length(mock_images(9))
      assert Utils.str_occurence(converted, gallery_mini_image_class) == length(mock_images(9))
    end

    test "edit exsit block will not change id value" do
      editor_json =
        set_items(
          "gallery",
          mock_images(9)
          |> Enum.with_index()
          |> Enum.map(fn {src, index} ->
            %{
              "index" => index,
              "src" => src,
              "caption" => "this is a caption 1"
            }
          end),
          "block-id-exsit"
        )

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, ~s(id="block-id-exsit")) == 1
    end

    test "invalid mode parse should raise error message" do
      editor_json = set_items("invalid-mode", [])
      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, err_msg} = Parser.to_html(editor_string)

      assert [
               %{block: "image", field: "items", message: "empty is not allowed", value: []},
               %{
                 block: "image",
                 field: "mode",
                 message: "should be: single | jiugongge | gallery"
               }
             ] == err_msg
    end

    test "invalid data parse should raise error message" do
      editor_json =
        set_items("single", [
          %{
            "index" => "invalid",
            "src" => "https://xxx"
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, err_msg} = Parser.to_html(editor_string)

      assert err_msg == [
               %{
                 block: "image(single)",
                 field: "index",
                 message: "should be: number",
                 value: "invalid"
               }
             ]
    end

    test "src should starts with https://" do
      editor_json =
        set_items("single", [
          %{
            "index" => 0,
            "src" => "src"
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, err_msg} = Parser.to_html(editor_string)

      assert err_msg ==
               [
                 %{
                   block: "image(single)",
                   field: "src",
                   message: "should starts with: https://",
                   value: "src"
                 }
               ]
    end
  end
end
