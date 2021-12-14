defmodule Helper.Converter.EditorToHTML.Class do
  @moduledoc """
  html article class names parsed from editor.js's json data

  currently use https://editorjs.io/ as rich-text editor
  # NOTE: DONOT CHANGE ONCE SET, OTHERWISE IT WILL CAUSE INCOMPATIBILITY ISSUE
  """

  @doc """
  get all the class names of the parsed editor.js's html parts
  """
  def article() do
    %{
      # root wrapper
      "viewer" => "article-viewer-wrapper",
      "unknow_block" => "unknow-block",
      "invalid_block" => "invalid-block",
      "hide" => "hide",
      # header
      "header" => %{
        "wrapper" => "header-wrapper",
        "header" => "header",
        "eyebrow_title" => "eyebrow-title",
        "footer_title" => "footer-title"
      },
      # quote block
      "quote" => %{
        "short_wrapper" => "quote-short",
        "long_wrapper" => "quote-long",
        "text" => "quote__text",
        "caption" => "quote-caption",
        "caption_line" => "quote-caption__line",
        "caption_text" => "quote-caption__text"
      },
      # list
      "list" => %{
        "wrapper" => "list-wrapper",
        "label" => "list-label",
        "label__default" => "list-label__default",
        "label__red" => "list-label__red",
        "label__green" => "list-label__green",
        "label__warn" => "list-label__warn",
        "unordered_list_prefix" => "list__item-unorder-prefix",
        "order_list_prefix" => "list__item-order-prefix",
        "list_item" => "list-item",
        "checklist_item" => "list-checklist__item",
        "checklist_checkbox" => "checklist__item-checkbox",
        "checklist_checkbox_checked" => "checklist__item-check-sign-checked",
        "checklist_checksign" => "checklist__item-check-sign",
        "text" => "list-item-text",
        "checklist_text" => "list-checklist__item-text",
        "indent_0" => "",
        "indent_1" => "list-indent-1",
        "indent_2" => "list-indent-2",
        "indent_3" => "list-indent-3"
      },
      "table" => %{
        "wrapper" => "table-wrapper",
        "cell" => "table-cell",
        "th_header" => "th_header",
        "td_stripe" => "td_stripe",
        "align_center" => "align-center",
        "align_left" => "align-left",
        "align_right" => "align-right"
      },
      "image" => %{
        "wrapper" => "image-wrapper",
        "single_image_wrapper" => "single-image",
        "single_image" => "image-picture",
        "image_caption" => "image-caption",
        # "single_caption"
        # jiugongge
        "jiugongge_image_wrapper" => "jiugongge-image",
        "jiugongge_image_block" => "jiugongge-block",
        "jiugongge_image" => "jiugongge-block-image",
        # gallery
        "gallery_image_wrapper" => "gallery-image",
        "gallery_image_inner" => "gallery-image-inner",
        "gallery_image_block" => "gallery-block",
        "gallery_image" => "gallery-block-image",
        # minimap
        "gallery_minimap" => "gallery-minimap",
        "gallery_minimap_image" => "gallery-minimap-block-image"
      },
      "people" => %{
        "wrapper" => "people-wrapper",
        # gallery
        "gallery_wrapper" => "gallery-wrapper",
        "gallery_previewer_wrapper" => "gallery-previewer-wrapper",
        "gallery_previewer_item" => "gallery-previewer-item",
        "gallery_previewer_active_item" => "gallery-previewer-item-active",
        "gallery_card_wrapper" => "gallery-card-wrapper",
        "gallery_avatar" => "gallery-avatar",
        "gallery_intro" => "gallery-intro",
        "gallery_intro_title" => "gallery-intro-title",
        "gallery_intro_bio" => "gallery-intro-bio",
        "gallery_intro_desc" => "gallery-intro-desc",
        "gallery_social_wrapper" => "gallery-social-wrapper",
        "gallery_social_icon" => "gallery-social-icon"
        ## social
      }
    }
  end
end
