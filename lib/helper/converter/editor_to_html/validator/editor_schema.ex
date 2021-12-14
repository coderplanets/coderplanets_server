defmodule Helper.Converter.EditorToHTML.Validator.EditorSchema do
  @moduledoc false

  # header
  @valid_header_level [1, 2, 3]

  # quote
  @valid_quote_mode ["short", "long"]

  # list
  @valid_list_mode ["checklist", "order_list", "unordered_list"]
  @valid_list_label_type ["green", "red", "warn", "default", nil]
  @valid_list_indent [0, 1, 2, 3]

  # table
  @valid_table_align ["left", "center", "right"]

  # image
  @valid_image_mode ["single", "jiugongge", "gallery"]

  # people
  @valid_people_mode ["gallery"]

  @spec get(String.t()) :: map | [parent: map, item: map]
  def get("editor") do
    %{
      "time" => [:number],
      "version" => [:string],
      "blocks" => [:list]
    }
  end

  def get("header") do
    %{
      "id" => [:string, required: false],
      "text" => [:string],
      "level" => [enum: @valid_header_level],
      "eyebrowTitle" => [:string, required: false],
      "footerTitle" => [:string, required: false]
    }
  end

  def get("paragraph") do
    %{
      "id" => [:string, required: false],
      "text" => [:string]
    }
  end

  def get("quote") do
    %{
      "id" => [:string, required: false],
      "text" => [:string],
      "mode" => [enum: @valid_quote_mode],
      "caption" => [:string, required: false]
    }
  end

  def get("list") do
    [
      parent: %{
        "id" => [:string, required: false],
        "mode" => [enum: @valid_list_mode],
        "items" => [:list, type: :map, allow_empty: false]
      },
      item: %{
        "checked" => [:boolean],
        "hideLabel" => [:boolean],
        "label" => [:string, required: false],
        "labelType" => [enum: @valid_list_label_type],
        "prefixIndex" => [:string, required: false],
        "indent" => [enum: @valid_list_indent],
        "text" => [:string]
      }
    ]
  end

  def get("table") do
    [
      parent: %{
        "id" => [:string, required: false],
        "columnCount" => [:number, min: 2],
        "items" => [:list, type: :map, allow_empty: false]
      },
      item: %{
        "text" => [:string],
        "align" => [enum: @valid_table_align],
        "isStripe" => [:boolean],
        "isHeader" => [:boolean, required: false],
        "width" => [:string, required: false]
      }
    ]
  end

  def get("image") do
    [
      parent: %{
        "id" => [:string, required: false],
        "mode" => [enum: @valid_image_mode],
        "items" => [:list, type: :map, allow_empty: false]
      },
      item: %{
        "src" => [:string, starts_with: "https://"],
        "index" => [:number],
        "caption" => [:string, required: false],
        "height" => [:string, required: false],
        "width" => [:string, required: false]
      }
    ]
  end

  def get("people") do
    [
      parent: %{
        "id" => [:string, required: false],
        "mode" => [enum: @valid_people_mode],
        "items" => [:list, type: :map, allow_empty: false]
      },
      item: %{
        "avatar" => [:string, starts_with: "https://"],
        "title" => [:string, required: false],
        "bio" => [:string, required: false],
        "desc" => [:string, required: false],
        "socials" => [:list, type: :map]
      }
    ]
  end

  def get(_) do
    %{}
  end
end
