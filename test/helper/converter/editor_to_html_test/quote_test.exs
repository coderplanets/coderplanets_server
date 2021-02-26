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

    @tag :wip2
    test "short quote parse should work" do
      editor_json = set_data("short", "short quote")
      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      short_wrapper_class = @class["short_wrapper"]
      caption_class = @class["caption"]

      assert Utils.str_occurence(converted, short_wrapper_class) == 1
      assert Utils.str_occurence(converted, "</blockquote>") == 1
      assert Utils.str_occurence(converted, caption_class) == 0
    end

    @tag :wip2
    test "long quote parse should work" do
      editor_json = set_data("long", "long quote", "caption")
      {:ok, editor_string} = Jason.encode(editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      long_wrapper_class = @class["long_wrapper"]
      caption_text_class = @class["caption_text"]

      assert Utils.str_occurence(converted, long_wrapper_class) == 1
      assert Utils.str_occurence(converted, "</blockquote>") == 1
      assert Utils.str_occurence(converted, caption_text_class) == 1
    end

    @tag :wip2
    test "long quote without caption parse should work" do
      editor_json = set_data("long", "long quote")
      {:ok, editor_string} = Jason.encode(editor_json)

      {:ok, converted} = Parser.to_html(editor_string)

      long_wrapper_class = @class["long_wrapper"]
      caption_text_class = @class["caption_text"]

      assert Utils.str_occurence(converted, long_wrapper_class) == 1
      assert Utils.str_occurence(converted, "</blockquote>") == 1
      assert Utils.str_occurence(converted, caption_text_class) == 0
    end

    @tag :wip2
    test "long quote without empty caption parse should work" do
      editor_json = set_data("long", "long quote", "")
      {:ok, editor_string} = Jason.encode(editor_json)

      {:ok, converted} = Parser.to_html(editor_string)

      long_wrapper_class = @class["long_wrapper"]
      caption_text_class = @class["caption_text"]

      assert Utils.str_occurence(converted, long_wrapper_class) == 1
      assert Utils.str_occurence(converted, "</blockquote>") == 1
      assert Utils.str_occurence(converted, caption_text_class) == 0
    end

    # @editor_json %{
    #   "time" => 1_567_250_876_713,
    #   "blocks" => [
    #     %{
    #       "type" => "paragraph",
    #       "data" => %{
    #         "text" => []
    #       }
    #     }
    #   ],
    #   "version" => "2.15.0"
    # }
    @tag :wip2
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
