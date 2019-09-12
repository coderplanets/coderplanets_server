defmodule Helper.Converter.MdToEditor do
  @moduledoc """
  parse markdown ast to editor json data

  see https://editorjs.io/
  """

  @supported_header ["h1", "h2", "h3", "h4", "h5", "h6"]

  @spec parse(binary | [any]) :: any
  def parse(mdstring) do
    {:ok, ast, _opt} = Earmark.as_ast(mdstring)
    # IO.inspect(ast, label: "raw ast")

    editor_blocks =
      Enum.reduce(ast, [], fn ast_item, acc ->
        parsed = parse_block(ast_item)
        acc ++ [parsed]
      end)

    # IO.inspect(editor_blocks, label: "final editor_blocks")
    editor_blocks
  end

  # parse markdown header to editor's header
  defp parse_block({type, _opt, content})
       when type in @supported_header do
    content_text =
      Enum.reduce(content, "", fn content_item, acc ->
        parsed = parse_inline(type, content_item)
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
  defp parse_block({"p", _opt, [{"img", [{"src", src}, _alt], []}]}) do
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

  defp parse_block({"p", _opt, content}) do
    content_text =
      Enum.reduce(content, "", fn content_item, acc ->
        parsed = parse_inline("p", content_item)

        acc <> parsed
      end)

    %{
      type: "paragraph",
      data: %{
        text: content_text
      }
    }
  end

  defp parse_block({"ul", [], content}) do
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

  defp parse_block({"ol", [], content}) do
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

  defp parse_block({"blockquote", _opt, content}) do
    %{
      type: "quote",
      data: %{
        text: parse_inline(content)
      }
    }
  end

  defp parse_block({"hr", _opt, _content}) do
    %{
      type: "delimiter",
      data: {}
    }
  end

  defp parse_block({_type, _opt, _content}) do
    # IO.inspect(name, label: "parse block")
    # IO.inspect(content, label: "content")
    %{}
  end

  # 字符串直接返回，作为 editor.js 中的 text/data/code 等字段
  defp parse_inline(content) when is_binary(content), do: content
  defp parse_inline([_type, content]), do: parse_inline(content)
  defp parse_inline([content]) when is_binary(content), do: parse_inline(content)

  defp parse_inline({"strong", [], content}) do
    "<b>#{parse_inline(content)}</b>"
  end

  #  NOTE:  editor.js 暂时不支持 del 标签，所以直接返回字符串内容即可
  # TODO:  del -> editor.s marker
  defp parse_inline({"del", [], [content]}), do: content
  # NOTE:  earmark parse italic as em
  defp parse_inline({"em", [], [content]}), do: inline_res("em", content)
  defp parse_inline({"em", [], content}), do: inline_res("em", content)
  defp parse_inline([{"em", [], content}]), do: inline_res("em", content)

  defp parse_inline({"li", [], content}) when is_list(content) do
    line =
      Enum.reduce(content, "", fn content_item, acc ->
        acc <> parse_inline(content_item)
      end)

    line
  end

  defp parse_inline({"li", [], content}), do: parse_inline(content)

  defp parse_inline([{"p", [], content}]) do
    line =
      Enum.reduce(content, "", fn content_item, acc ->
        acc <> parse_inline(content_item)
      end)

    line
  end

  defp parse_inline({"code", [{"class", "inline"}], content}), do: inline_res("code", content)
  defp parse_inline([{"code", [{"class", "inline"}], content}]), do: inline_res("code", content)

  defp parse_inline({"a", [{"href", href}], [content]}) do
    "<a href=\"#{href}\">#{content}</a>"
  end

  defp inline_res("em", content), do: "<i>#{parse_inline(content)}</i>"

  defp inline_res("code", content),
    do: "<code class=\"inline-code\">#{parse_inline(content)}</code>"

  defp parse_inline(_type, content) when is_binary(content), do: content

  defp parse_inline(header, {_type, _opt, [content]})
       when header in @supported_header do
    parse_inline(content)
  end

  # when header in @supported_header do
  defp parse_inline("p", content), do: parse_inline(content)

  # 判断是否为 editorjs 的 checklist
  defp is_checklist_ul?(content) when is_list(content) do
    Enum.all?(content, fn {"li", [], li_item} ->
      li_item |> Enum.at(0) |> String.starts_with?(["[ ] ", "[x] ", "[X] "])
    end)
  end
end
