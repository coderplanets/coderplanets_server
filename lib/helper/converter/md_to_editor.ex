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
    level = if level >= 4, do: 3, else: level

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
        mode: "single",
        items: [
          %{
            index: 0,
            src: src
          }
        ]
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

            acc ++
              [
                %{
                  "text" => parsed,
                  "indent" => 0,
                  "checked" => false,
                  "hideLabel" => true,
                  label: "",
                  labelType: "default"
                }
              ]
          end)

        %{
          type: "list",
          data: %{
            mode: "unordered_list",
            items: items
          }
        }

      # checklist
      true ->
        items =
          Enum.reduce(content, [], fn content_item, acc ->
            parsed = parse_inline(content_item)
            IO.inspect(parsed, label: "the parsed")

            acc ++
              [
                %{
                  # 4 表示 [ ] 或 [x] 占用的 4 个 size
                  "text" => String.slice(parsed, 4, byte_size(parsed)),
                  "checked" => String.starts_with?(parsed, ["[x] ", "[X] "]),
                  "indent" => 0,
                  "hideLabel" => true,
                  label: "",
                  labelType: "default"
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

        acc ++
          [
            %{
              "text" => parsed,
              "indent" => 0,
              "checked" => false,
              "hideLabel" => true,
              "prefixIndex" => (length(acc) + 1) |> to_string,
              label: "",
              labelType: "default"
            }
          ]
      end)

    %{
      type: "list",
      data: %{
        mode: "order_list",
        items: items
      }
    }
  end

  defp parse_block({"blockquote", _opt, content, _html_ast}) do
    %{
      type: "quote",
      data: %{
        mode: "short",
        text: parse_inline(content)
      }
    }
  end

  defp parse_block("<br/>") do
    %{
      type: "paragraph",
      data: %{
        text: ""
      }
    }
  end

  defp parse_block({"hr", _opt, _content, _html_ast}) do
    %{
      type: "paragraph",
      data: %{
        text: ""
      }
    }
  end

  defp parse_block({"table", _opt, _content, _html_ast}) do
    %{
      type: "paragraph",
      data: %{
        text: "table: todo"
      }
    }

    # %{
    #   type: "table",
    #   data: %{
    #     columnCount: 3,
    #     items: []
    #   }
    # }
  end

  defp parse_block({"code", _opt, _content, _html_ast}) do
    %{
      type: "paragraph",
      data: %{
        text: "code: todo"
      }
    }
  end

  defp parse_block({_type, _opt, _content, _html_ast}) do
    %{
      type: "paragraph",
      data: %{
        text: ""
      }
    }
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

  defp parse_inline({"img", [{"src", src}, _], [], %{}}) do
    # TODO:
    src
  end

  defp parse_inline({"a", [{"href", href}], [content], _}) do
    content |> wrap_with("a", href)
  end

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

  defp parse_inline({"h3", [], [{"a", [{"href", href}], [content], %{}}], %{}}) do
    content |> wrap_with("a", href) |> wrap_with("h3")
  end

  defp parse_inline({"code", [{"class", "inline"}], content, _html_ast}),
    do: content |> wrap_with("code")

  defp parse_inline([{"code", [{"class", "inline"}], content, _html_ast}]),
    do: content |> wrap_with("code")

  # TODO: use wrap_with
  defp parse_inline([{"a", [{"href", href}], [content], _html_ast}]) do
    content |> wrap_with("a", href)
  end

  defp parse_inline({"br", [], [], %{}}) do
    ""
  end

  # TODO: too much edge cases
  defp parse_inline(_), do: "unkown inline block"

  # 判断是否为 editorjs 的 checklist
  defp is_checklist_ul?(content) when is_list(content) do
    Enum.all?(content, fn {"li", [], li_item, _html_ast} ->
      # IO.inspect(li_item, label: "li_item before")
      # li_item = parse_inline(li_item)
      # IO.inspect(li_item, label: "li_item")

      # li_item |> Enum.at(0) |> String.starts_with?(["[ ] ", "[x] ", "[X] "])
      false
    end)
  end

  # wrap the cotnent with html tag
  defp wrap_with(content, "em"), do: "<i>#{parse_inline(content)}</i>"

  defp wrap_with(content, "code"),
    do: "<code class=\"inline-code\">#{parse_inline(content)}</code>"

  defp wrap_with(content, "b"), do: "<b>#{parse_inline(content)}</b>"
  defp wrap_with(content, "a", href), do: "<a href=\"#{href}\">#{parse_inline(content)}</a>"

  defp wrap_with(content, "h3"), do: "<h3>#{parse_inline(content)}</h3>"
end
