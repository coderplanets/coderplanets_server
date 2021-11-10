defmodule Helper.AuditBot do
  @moduledoc """
  敏感词检测服务

  # see more details in doc https://ai.baidu.com/ai-doc/ANTIPORN/Nk3h6xbb2

  return example

  give text = "<div>M卖批, 这也太操蛋了, 党中央</div>"

  got

  %{
    illegal_reason: ["政治敏感", "低俗辱骂"],
    illegal_words: ["党中央", "操蛋", "卖批"],
    is_legal: false
  }
  """
  # import Helper.Utils, only: [done: 1]

  # conclusionType === 1
  @conclusionOK 1

  @token "24.4d53f20a8a47348f5a90011bc1a16e84.2592000.1639149221.282335-25148796"
  @url "https://aip.baidubce.com"
  @endpoint "#{@url}/rest/2.0/solution/v1/text_censor/v2/user_defined?access_token=#{@token}"

  def analysis(:text, text) do
    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    text = text |> HtmlSanitizeEx.strip_tags()

    with {:ok, result} <- HTTPoison.post(@endpoint, {:form, [text: text]}, headers) do
      parse_result(result)
    end
  end

  defp parse_result(%HTTPoison.Response{body: body, status_code: 200}) do
    with {:ok, result} <- Jason.decode(body) do
      case result["conclusionType"] === @conclusionOK do
        true -> {:ok, %{is_legal: true, illegal_reason: [], illegal_words: []}}
        false -> parse_illegal(result)
      end
    end
  end

  defp parse_illegal(result) do
    data = result["data"]

    {:error,
     %{
       is_legal: false,
       illegal_reason: gather_reason(data),
       illegal_words: gather_keyworks(data)
     }}
  end

  defp gather_reason(data) do
    data
    |> Enum.reduce([], fn item, acc ->
      reason = item["subType"] |> transSubType
      acc ++ [reason]
    end)
  end

  defp gather_keyworks(data) do
    data
    |> Enum.reduce([], fn item, acc ->
      words = gather_hits(item["hits"])
      acc ++ words
    end)
  end

  defp gather_hits(hits) do
    hits
    |> Enum.reduce([], fn hit, acc ->
      acc ++ hit["words"]
    end)
    |> Enum.uniq()
  end

  defp transSubType(0), do: "低质灌水"
  defp transSubType(1), do: "暴恐违禁"
  defp transSubType(2), do: "文本色情"
  defp transSubType(3), do: "政治敏感"
  defp transSubType(4), do: "恶意 / 软文推广"
  defp transSubType(5), do: "低俗辱骂"
  defp transSubType(6), do: "恶意 / 软文推广"
  defp transSubType(7), do: "恶意 / 软文推广"
  defp transSubType(8), do: "恶意 / 软文推广"
  defp transSubType(_), do: "疑似灌水"
end
