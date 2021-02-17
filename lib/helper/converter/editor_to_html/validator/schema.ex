defmodule Helper.Converter.EditorToHTML.Validator.Schema do
  @moduledoc false

  # header
  @valid_header_level [1, 2, 3]

  # list
  @valid_list_mode ["checklist", "order_list", "unorder_list"]
  @valid_list_label_type ["success", "done", "todo"]
  @valid_list_indent [0, 1, 2, 3, 4]

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
      parent: %{"mode" => [enum: @valid_list_mode]},
      item: %{
        "checked" => [:boolean],
        "hideLabel" => [:boolean],
        "label" => [:string],
        "labelType" => [enum: @valid_list_label_type],
        "indent" => [enum: @valid_list_indent],
        "text" => [:string]
      }
    ]
  end

  def get(_) do
    %{}
  end
end
