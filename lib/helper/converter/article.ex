defmodule Helper.Converter.Article do
  @moduledoc """
  convert body

  {:ok, { body: body, body_html: body_html }} = Converter.Article.parse_body(body)
  """
  import Helper.Utils, only: [done: 1, uid: 0, keys_to_strings: 1, get_config: 2]

  alias Helper.Converter.{EditorToHTML, HtmlSanitizer}

  @article_digest_length get_config(:article, :digest_length)

  def default_rich_text() do
    """
    {
      "time": 2018,
      "blocks": [],
      "version": "2.22.0"
    }
    """
  end

  @doc """
  parse article body field
  """
  @spec parse_body(String.t()) ::
          {:ok, %{body: String.t(), body_map: Map.t(), body_html: String.t()}}
  def parse_body(body) when is_binary(body) do
    with {:ok, body_map} <- to_editor_map(body),
         {:ok, body_html} <- EditorToHTML.to_html(body_map),
         {:ok, body_encode} <- Jason.encode(body_map) do
      %{body: body_encode, body_html: body_html, body_map: body_map}
      |> done
    end
  end

  def parse_body(_), do: {:error, "wrong body fmt"}

  @doc """
  parse digest by concat all the paragraph blocks
  """
  def parse_digest(%{"blocks" => blocks} = body_map) when is_map(body_map) do
    digest_blocks = Enum.filter(blocks, &(&1["type"] == "paragraph"))

    Enum.reduce(digest_blocks, "", fn block, acc ->
      text = block["data"]["text"] |> HtmlSanitizer.strip_all_tags()
      acc <> text <> "   "
    end)
    |> String.trim_trailing()
    |> parse_other_blocks_ifneed(blocks)
    |> String.slice(0, @article_digest_length)
    |> done
  end

  def parse_digest(_), do: {:ok, "无可预览摘要"}

  # 如果文章里没有段落，可以使用列表内容（如果有的话）作为预览内容
  defp parse_other_blocks_ifneed("", blocks) do
    list_blocks = Enum.filter(blocks, &(&1["type"] == "list"))

    digest =
      case list_blocks do
        [] ->
          "无可预览摘要"

        _ ->
          digest_block = list_blocks |> List.first()

          Enum.reduce(digest_block["data"]["items"], "", fn item, acc ->
            text = item["text"]
            acc <> text <> "   "
          end)
          |> String.trim_trailing()
          |> HtmlSanitizer.strip_all_tags()
          |> String.slice(0, @article_digest_length)
      end

    digest
  end

  defp parse_other_blocks_ifneed(paragraph_digest, _blocks) do
    paragraph_digest
  end

  @doc """
  decode article body string to editor map and assign id for each block
  """
  def to_editor_map(string) when is_binary(string) do
    with {:ok, map} <- Jason.decode(string),
         {:ok, _} <- EditorToHTML.Validator.is_valid(map) do
      blocks = Enum.map(map["blocks"], &Map.merge(&1, %{"id" => get_block_id(&1)}))
      Map.merge(map, %{"blocks" => blocks}) |> done
    end
  end

  # for markdown blocks
  def to_editor_map(blocks) when is_list(blocks) do
    Enum.map(blocks, fn block ->
      block = keys_to_strings(block)
      Map.merge(block, %{"id" => get_block_id(block)})
    end)
    |> done
  end

  def to_editor_map(_), do: {:error, "wrong editor fmt"}

  # use custom block id instead of editor.js's default block id
  defp get_block_id(%{"id" => id} = block) when not is_nil(id) do
    case String.starts_with?(block["id"], "block-") do
      true -> id
      false -> "block-#{uid()}"
    end
  end

  defp get_block_id(_), do: "block-#{uid()}"
end
