defmodule Helper.Converter.EditorToHTML.Validator.EditorSchema do
  @moduledoc false

  # header
  @valid_header_level [1, 2, 3]

  # list
  @valid_list_mode ["checklist", "order_list", "unorder_list"]
  @valid_list_label_type ["green", "red", "warn", "default"]
  @valid_list_indent [0, 1, 2, 3]

  # table
  @valid_table_align ["left", "center", "right"]

  def get("editor") do
    %{
      "time" => [:number],
      "version" => [:string],
      "blocks" => [:list]
    }
  end

  def get("header") do
    %{
      "text" => [:string],
      "level" => [enum: @valid_header_level],
      "eyebrowTitle" => [:string, required: false],
      "footerTitle" => [:string, required: false]
    }
  end

  def get("paragraph"), do: %{"text" => [:string]}

  def get("list") do
    [
      parent: %{"mode" => [enum: @valid_list_mode], "items" => [:list]},
      item: %{
        "checked" => [:boolean],
        "hideLabel" => [:boolean],
        "label" => [:string],
        "labelType" => [enum: @valid_list_label_type],
        "prefixIndex" => [:string, required: false],
        "indent" => [enum: @valid_list_indent],
        "text" => [:string]
      }
    ]
  end

  def get("table") do
    [
      parent: %{"columnCount" => [:number, min: 2], "items" => [:list]},
      item: %{
        "text" => [:string],
        "align" => [enum: @valid_table_align],
        "isStripe" => [:boolean],
        "isHeader" => [:boolean, required: false],
        "width" => [:string, required: false]
      }
    ]
  end

  def get(_) do
    %{}
  end
end
