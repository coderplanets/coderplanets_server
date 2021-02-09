defmodule Helper.Metric.Article do
  @moduledoc """
  html article class names parsed from editor.js's json data

  currently use https://editorjs.io/ as rich-text editor
  # NOTE: DONOT CHANGE ONCE SET, OTHERWISE IT WILL CAUSE INCOMPATIBILITY ISSUE
  """

  @doc """
  get all the class names of the parsed editor.js's html parts
  """
  def class_names(:html) do
    %{
      # root wrapper
      viewer: "article-viewer-wrapper",
      unknow_block: "unknow-block",
      invalid_block: "invalid-block",
      # header
      header: %{
        wrapper: "header-wrapper",
        eyebrow_title: "eyebrow-title",
        footer_title: "footer-title"
      }
    }
  end
end
