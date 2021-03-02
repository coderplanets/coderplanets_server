defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.Image do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHTML, as: Parser
  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Utils

  @root_class Class.article()
  @class get_in(@root_class, ["image"])

  @images [
    "https://images.unsplash.com/photo-1506034861661-ad49bbcf7198?ixlib=rb-1.2.1&ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&auto=format&fit=crop&w=1350&q=80",
    "https://images.unsplash.com/photo-1614607206234-f7b56bdff6e7?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=634&q=80",
    "https://images.unsplash.com/photo-1614526261139-1e5ebbd5086c?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80"
    # "https://images.unsplash.com/photo-1614366559478-edf9d1cc4719?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=634&q=80",
    # "https://images.unsplash.com/photo-1614588108027-22a021c8d8e1?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1349&q=80"
    # "https://images.unsplash.com/photo-1614522407266-ad3c5fa6bc24?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1352&q=80",
    # "https://images.unsplash.com/photo-1601933470096-0e34634ffcde?ixid=MXwxMjA3fDF8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80",
    # "https://images.unsplash.com/photo-1614598943918-3d0f1e65c22c?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80",
    # "https://images.unsplash.com/photo-1614542530265-7a46ededfd64?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=634&q=80"
  ]

  describe "[image block unit]" do
    defp set_items(mode, items, id \\ "") do
      %{
        "time" => 1_567_250_876_713,
        "blocks" => [
          %{
            "type" => "image",
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

    @tag :wip
    test "single image parse should work" do
      editor_json =
        set_items("single", [
          %{
            "index" => 0,
            "src" => @images |> List.first(),
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

    @tag :wip
    test "single image parse should work without wight && height" do
      editor_json =
        set_items("single", [
          %{
            "index" => 0,
            "src" => @images |> List.first(),
            "caption" => "this is a caption"
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      # unorder_list_prefix_class = @class["unorder_list_prefix"]
      assert Utils.str_occurence(converted, "<img") == 1
      assert Utils.str_occurence(converted, "width:") == 0
      assert Utils.str_occurence(converted, "height:") == 0

      single_image_wrapper_class = @class["single_image_wrapper"]
      assert Utils.str_occurence(converted, single_image_wrapper_class) == 1
    end

    @tag :wip
    test "single image parse should work without caption" do
      editor_json =
        set_items("single", [
          %{
            "index" => 0,
            "src" => @images |> List.first()
          }
        ])

      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      # unorder_list_prefix_class = @class["unorder_list_prefix"]
      assert Utils.str_occurence(converted, "<img") == 1
      assert Utils.str_occurence(converted, "width:") == 0
      assert Utils.str_occurence(converted, "height:") == 0

      single_image_wrapper_class = @class["single_image_wrapper"]
      assert Utils.str_occurence(converted, single_image_wrapper_class) == 1

      image_caption_class = @class["image_caption"]
      assert Utils.str_occurence(converted, image_caption_class) == 0
    end

    @tag :wip2
    test "jiugongge image parse should work" do
      editor_json =
        set_items(
          "jiugongge",
          @images
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
      assert Utils.str_occurence(converted, jiugongge_image_class) == length(@images)
    end

    @tag :wip2
    test "gallery image parse should work" do
      editor_json =
        set_items(
          "gallery",
          @images
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

      assert Utils.str_occurence(converted, gallery_image_class) == length(@images)
      assert Utils.str_occurence(converted, gallery_mini_image_class) == length(@images)
    end

    # @tag :wip
    # test "edit exsit block will not change id value" do
    #   editor_json =
    #     set_items(
    #       "order_list",
    #       [
    #         %{
    #           "checked" => true,
    #           "hideLabel" => false,
    #           "indent" => 0,
    #           "label" => "label",
    #           "labelType" => "default",
    #           "prefixIndex" => "1.",
    #           "text" =>
    #             "一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。"
    #         }
    #       ],
    #       "exsit"
    #     )

    #   {:ok, editor_string} = Jason.encode(editor_json)
    #   {:ok, converted} = Parser.to_html(editor_string)

    #   assert Utils.str_occurence(converted, "id=\"exsit\"") == 1
    # end

    # @tag :wip
    # test "basic checklist parse should work" do
    #   editor_json =
    #     set_items("checklist", [
    #       %{
    #         "checked" => true,
    #         "hideLabel" => false,
    #         "indent" => 0,
    #         "label" => "label",
    #         "labelType" => "default",
    #         "text" =>
    #           "一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。"
    #       },
    #       %{
    #         "checked" => false,
    #         "hideLabel" => false,
    #         "indent" => 0,
    #         "label" => "label",
    #         "labelType" => "default",
    #         "text" => "list item"
    #       },
    #       %{
    #         "checked" => false,
    #         "hideLabel" => false,
    #         "indent" => 1,
    #         "label" => "green",
    #         "labelType" => "green",
    #         "text" => "list item"
    #       },
    #       %{
    #         "checked" => false,
    #         "hideLabel" => false,
    #         "indent" => 1,
    #         "label" => "red",
    #         "labelType" => "red",
    #         "text" => "list item"
    #       }
    #     ])

    #   {:ok, editor_string} = Jason.encode(editor_json)
    #   {:ok, converted} = Parser.to_html(editor_string)

    #   checked_class = @class["checklist_checkbox_checked"]
    #   assert Utils.str_occurence(converted, checked_class) == 1
    # end

    # @tag :wip
    # test "checklist without label parse should work" do
    #   editor_json =
    #     set_items("checklist", [
    #       %{
    #         "checked" => true,
    #         "hideLabel" => true,
    #         "indent" => 0,
    #         "label" => "label",
    #         "labelType" => "default",
    #         "text" => "list item"
    #       },
    #       %{
    #         "checked" => false,
    #         "hideLabel" => true,
    #         "indent" => 0,
    #         "label" => "label",
    #         "labelType" => "default",
    #         "text" => "list item"
    #       }
    #     ])

    #   {:ok, editor_string} = Jason.encode(editor_json)
    #   {:ok, converted} = Parser.to_html(editor_string)

    #   label_class = @class["label"]
    #   assert Utils.str_occurence(converted, label_class) == 0
    # end

    # @tag :wip
    # test "invalid list mode parse should raise error message" do
    #   editor_json = set_items("invalid-mode", [])
    #   {:ok, editor_string} = Jason.encode(editor_json)
    #   {:error, err_msg} = Parser.to_html(editor_string)

    #   assert err_msg == [
    #            %{
    #              block: "list",
    #              field: "mode",
    #              message: "should be: checklist | order_list | unorder_list"
    #            }
    #          ]
    # end

    # @tag :wip
    # test "invalid list data parse should raise error message" do
    #   editor_json =
    #     set_items("checklist", [
    #       %{
    #         "checked" => true,
    #         "hideLabel" => "invalid",
    #         "indent" => 5,
    #         "label" => "label",
    #         "labelType" => "default",
    #         "text" => "list item"
    #       }
    #     ])

    #   {:ok, editor_string} = Jason.encode(editor_json)
    #   {:error, err_msg} = Parser.to_html(editor_string)

    #   assert err_msg == [
    #            %{
    #              block: "list(checklist)",
    #              field: "hideLabel",
    #              message: "should be: boolean",
    #              value: "invalid"
    #            },
    #            %{
    #              block: "list(checklist)",
    #              field: "indent",
    #              message: "should be: 0 | 1 | 2 | 3"
    #            }
    #          ]
    # end

    # @tag :wip
    # test "invalid indent field should get error" do
    #   editor_json =
    #     set_items("checklist", [
    #       %{
    #         "checked" => true,
    #         "hideLabel" => true,
    #         "indent" => 10,
    #         "label" => "label",
    #         "labelType" => "default",
    #         "text" => "list item"
    #       }
    #     ])

    #   {:ok, editor_string} = Jason.encode(editor_json)
    #   {:error, error} = Parser.to_html(editor_string)

    #   assert error === [
    #            %{
    #              block: "list(checklist)",
    #              field: "indent",
    #              message: "should be: 0 | 1 | 2 | 3"
    #            }
    #          ]
    # end
  end
end
