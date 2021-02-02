defmodule Helper.Converter.MdToEditor do
  @moduledoc """
  parse markdown ast to editor json data

  NOTE: HTML is not parsed recursively or detected in all conditons right now, though GFM compliance is a goal.

  But for now the following holds:
  A HTML Block defined by a tag starting a line and the same tag starting a different line is parsed as one HTML AST node, marked with %{verbatim: true}

  for markdown parser, see https://hexdocs.pm/earmark/Earmark.html
  for editor format, see https://editorjs.io/
  """

  @supported_header ["h1", "h2", "h3", "h4", "h5", "h6"]

  @spec parse(binary | [any]) :: any
  def parse(markdown) do
    {:ok, ast, _opt} = EarmarkParser.as_ast(markdown)

    editor_blocks =
      Enum.reduce(ast, [], fn ast_item, acc ->
        parsed = parse_block(ast_item)
        acc ++ [parsed]
      end)

    # IO.inspect(editor_blocks, label: "final editor_blocks")
    editor_blocks
  end

  # parse markdown header to editor's header
  defp parse_block({type, _opt, content, html_ast})
       when type in @supported_header do
    content_text =
      Enum.reduce(content, "", fn content_item, acc ->
        parsed = parse_inline(type, content_item, html_ast)

        acc <> parsed
      end)

    # IO.inspect(content_text, label: "h-type content_text")
    [_, level] = String.split(type, "h")
    level = String.to_integer(level)

    %{
      type: "header",
      data: %{
        text: content_text,
        level: level
      }
    }
  end

  # parse markdown paragraph to editor's paragraph
  # parse image
  defp parse_block({"p", _opt, [{"img", [{"src", src}, _alt], [], _img_html_ast}], _html_ast}) do
    %{
      type: "image",
      data: %{
        file: %{
          url: src
        },
        caption: "",
        withBorder: false,
        stretched: false,
        withBackground: false
      }
    }
  end

  defp parse_block({"p", _opt, content, html_ast}) do
    content_text =
      Enum.reduce(content, "", fn content_item, acc ->
        parsed = parse_inline("p", content_item, html_ast)

        acc <> parsed
      end)

    %{
      type: "paragraph",
      data: %{
        text: content_text
      }
    }
  end

  defp parse_block({"ul", [], content, _html_ast}) do
    case is_checklist_ul?(content) do
      # normal ul list
      false ->
        items =
          Enum.reduce(content, [], fn content_item, acc ->
            parsed = parse_inline(content_item)
            acc ++ [parsed]
          end)

        %{
          type: "list",
          data: %{
            style: "unordered",
            items: items
          }
        }

      # checklist
      true ->
        items =
          Enum.reduce(content, [], fn content_item, acc ->
            parsed = parse_inline(content_item)

            acc ++
              [
                %{
                  # 4 表示 [ ] 或 [x] 占用的 4 个 size
                  "text" => String.slice(parsed, 4, byte_size(parsed)),
                  "checked" => String.starts_with?(parsed, ["[x] ", "[X] "])
                }
              ]
          end)

        %{
          type: "checklist",
          data: %{
            items: items
          }
        }
    end
  end

  defp parse_block({"ol", [], content, _html_ast}) do
    items =
      Enum.reduce(content, [], fn content_item, acc ->
        parsed = parse_inline(content_item)
        acc ++ [parsed]
      end)

    %{
      type: "list",
      data: %{
        style: "ordered",
        items: items
      }
    }
  end

  defp parse_block({"blockquote", _opt, content, _html_ast}) do
    %{
      type: "quote",
      data: %{
        text: parse_inline(content)
      }
    }
  end

  defp parse_block({"hr", _opt, _content, _html_ast}) do
    %{
      type: "delimiter",
      data: {}
    }
  end

  defp parse_block({_type, _opt, _content, _html_ast}) do
    # IO.inspect(name, label: "parse block")
    # IO.inspect(content, label: "content")
    %{}
  end

  defp parse_inline(_type, content, _html_ast), do: parse_inline(content)

  defp parse_inline([_type, content]), do: parse_inline(content)
  defp parse_inline([content]) when is_binary(content), do: parse_inline(content)
  defp parse_inline(content) when is_binary(content), do: content
  #  NOTE:  editor.js 暂时不支持 del 标签，所以直接返回字符串内容即可
  # TODO:  del -> editor.s marker
  # NOTE:  earmark parse italic as em
  defp parse_inline({"em", [], [content], _html_ast}), do: content |> wrap_with("em")
  defp parse_inline({"em", [], content, _html_ast}), do: content |> wrap_with("em")
  defp parse_inline([{"em", [], content, _html_ast}]), do: content |> wrap_with("em")
  defp parse_inline({"strong", [], content, _html_ast}), do: content |> wrap_with("b")
  defp parse_inline({"del", [], [content], _html_ast}), do: content

  defp parse_inline({"li", [], content, _html_ast}) when is_list(content) do
    line =
      Enum.reduce(content, "", fn content_item, acc ->
        acc <> parse_inline(content_item)
      end)

    line
  end

  defp parse_inline({"li", [], content, _html_ast}), do: parse_inline(content)

  defp parse_inline([{"p", [], content, _html_ast}]) do
    line =
      Enum.reduce(content, "", fn content_item, acc ->
        acc <> parse_inline(content_item)
      end)

    line
  end

  defp parse_inline({"code", [{"class", "inline"}], content, _html_ast}),
    do: content |> wrap_with("code")

  defp parse_inline([{"code", [{"class", "inline"}], content, _html_ast}]),
    do: content |> wrap_with("code")

  # TODO: use wrap_with
  defp parse_inline({"a", [{"href", href}], [content], _html_ast}) do
    "<a href=\"#{href}\">#{content}</a>"
  end

  # 判断是否为 editorjs 的 checklist
  defp is_checklist_ul?(content) when is_list(content) do
    Enum.all?(content, fn {"li", [], li_item, _html_ast} ->
      li_item |> Enum.at(0) |> String.starts_with?(["[ ] ", "[x] ", "[X] "])
    end)
  end

  # wrap the cotnent with html tag
  defp wrap_with(content, "em"), do: "<i>#{parse_inline(content)}</i>"

  defp wrap_with(content, "code"),
    do: "<code class=\"inline-code\">#{parse_inline(content)}</code>"

  defp wrap_with(content, "b"), do: "<b>#{parse_inline(content)}</b>"
end
