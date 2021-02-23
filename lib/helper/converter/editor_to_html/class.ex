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
      # header
      "header" => %{
        "wrapper" => "header-wrapper",
        "header" => "header",
        "eyebrow_title" => "eyebrow-title",
        "footer_title" => "footer-title"
      },
      # list
      "list" => %{
        "wrapper" => "list-wrapper",
        "label" => "list-label",
        "label__default" => "list-label__default",
        "label__red" => "list-label__red",
        "label__green" => "list-label__green",
        "label__warn" => "list-label__warn",
        "unorder_list_prefix" => "list__item-unorder-prefix",
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
      }
    }
  end
end
