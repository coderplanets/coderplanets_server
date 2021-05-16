defmodule GroupherServer.Test.Helper.Converter.EditorToHTML.Quote do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Converter.EditorToHTML, as: Parser

  alias Helper.Utils

  @root_class Class.article()
  @class get_in(@root_class, ["quote"])

  describe "[quote block]" do
    defp set_data(mode, text, caption \\ nil) do
      data =
        case caption do
          nil ->
            %{
              "mode" => mode,
              "text" => text
            }

          _ ->
            %{
              "mode" => mode,
              "text" => text,
              "caption" => caption
            }
        end

      %{
        "time" => 1_567_250_876_713,
        "blocks" => [
          %{
            "type" => "quote",
            "data" => data
          }
        ],
        "version" => "2.15.0"
      }
    end

    test "short quote parse should work" do
      editor_json = set_data("short", "short quote")
      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, "id=") == 1

      assert Utils.str_occurence(converted, @class["short_wrapper"]) == 1
      assert Utils.str_occurence(converted, "</blockquote>") == 1
      assert Utils.str_occurence(converted, @class["caption"]) == 0
    end

    test "long quote parse should work" do
      editor_json = set_data("long", "long quote", "caption")
      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, @class["long_wrapper"]) == 1
      assert Utils.str_occurence(converted, "</blockquote>") == 1
      assert Utils.str_occurence(converted, @class["caption_text"]) == 1
    end

    test "long quote without caption parse should work" do
      editor_json = set_data("long", "long quote")
      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, @class["long_wrapper"]) == 1
      assert Utils.str_occurence(converted, "</blockquote>") == 1
      assert Utils.str_occurence(converted, @class["caption_text"]) == 0
    end

    test "long quote without empty caption parse should work" do
      editor_json = set_data("long", "long quote", "")
      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert Utils.str_occurence(converted, @class["long_wrapper"]) == 1
      assert Utils.str_occurence(converted, "</blockquote>") == 1
      assert Utils.str_occurence(converted, @class["caption_text"]) == 0
    end

    test "invalid quote should have invalid hint" do
      editor_json = set_data("none_exsit", "long quote", "")
      {:ok, editor_string} = Jason.encode(editor_json)
      {:error, error} = Parser.to_html(editor_string)

      assert error == [
               %{block: "quote", field: "mode", message: "should be: short | long"}
             ]
    end
  end
end
