defmodule Helper.Converter.EditorToHTML.Validator.Schema do
  @moduledoc false

  @valid_header_level [1, 2, 3]

  def get("header") do
    %{
      "text" => [:string],
      "level" => [enum: @valid_header_level],
      "eyebrowTitle" => [:string, required: false],
      "footerTitle" => [:string, required: false]
    }
  end

  def get("paragraph") do
    %{"text" => [:string]}
  end

  def get(_) do
    %{}
  end
end
