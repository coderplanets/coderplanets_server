defmodule Helper.Converter.Article do
  @moduledoc """
  convert body

  {:ok, { body: body, body_html: body_html }} = Converter.Article.body_parse(body)
  """
  import Helper.Utils, only: [done: 1, uid: 0]
  alias Helper.Converter.EditorToHTML

  @doc """
  parse article body field
  """
  @spec body_parse(String.t()) :: {:ok, %{body: Map.t(), body_html: String.t()}}
  def body_parse(body) when is_binary(body) do
    with {:ok, body_map} <- to_editor_map(body),
         {:ok, body_html} <- EditorToHTML.to_html(body_map),
         {:ok, body_encode} <- Jason.encode(body_map) do
      %{body: body_encode, body_html: body_html} |> done
    end
  end

  def body_parse(_), do: {:error, "wrong body fmt"}

  @doc """
  decode article body string to editor map and assign id for each block
  """
  def to_editor_map(string) when is_binary(string) do
    with {:ok, map} <- Jason.decode(string) do
      blocks =
        Enum.map(map["blocks"], fn block ->
          block_id = if is_id_valid?(block), do: block["id"], else: "block-#{uid()}"

          Map.merge(block, %{"id" => block_id})
        end)

      Map.merge(map, %{"blocks" => blocks}) |> done
    end
  end

  def to_editor_map(_), do: {:error, "wrong editor fmt"}

  # use custom block id instead of editor.js's default block id
  defp is_id_valid?(block) when is_map(block) do
    Map.has_key?(block, "id") and String.starts_with?(block["id"], "block-")
  end

  defp is_id_valid?(_), do: false
end
