defmodule GroupherServer.CMS.Delegate.BlockTasks do
  @moduledoc """
  run tasks in every article blocks if need
  """
  import Helper.Utils, only: [get_config: 2]
  import GroupherServer.CMS.Helper.Matcher

  alias GroupherServer.Repo

  alias GroupherServer.CMS.Model.CitedContent
  alias Helper.ORM

  @site_host get_config(:general, :site_host)
  @article_threads get_config(:article, :threads)
  @valid_article_prefix Enum.map(@article_threads, &"#{@site_host}/#{&1}/")

  """
  我被谁引用了 是最重要的信息
  我引用了谁不重要，自己扫帖子就行了
  cited_thread, cited_article_id, [xxx_article]_id, [block_id, cited_block_id],

  POST post_333 -> cited_article_333, [[block_3, cited_block_23]]

  cited_type, cited_content_id, [contents]_id, [block_id, cited_block_id],

  cited_type: thread or comment
  content: article or comment
  # cited_article_comment_id, [xxx_article]_id, [block_id, cited_block_id],
  """

  # reference
  # mention

  def handle(%{body: body} = article) do
    with {:ok, body_map} <- Jason.decode(body) do
      run_tasks(:cite, article, body_map["blocks"])
    end
  end

  defp run_tasks(:cite, article, blocks) do
    article = article |> Repo.preload(author: :user)

    # NOTE:
    cited_contents =
      blocks
      |> Enum.reduce([], &(&2 ++ get_cited_contents_per_block(article, &1)))
      |> merge_same_cited_article_block

    IO.inspect(cited_contents, label: "fuck all")

    # CitedContent |>  ORM.create
  end

  @doc """
  e.g:
  [
    %{
      block_linker: ["block-zByQI"],
      cited_by_id: 190058,
      cited_by_type: "POST",
      post_id: 190059,
      user_id: 1413053
    },
    %{
      block_linker: ["block-zByQI"],
      cited_by_id: 190057,
      cited_by_type: "POST",
      post_id: 190059,
      user_id: 1413053
    },
    %{
      block_linker: ["block-ZgKJs"],
      cited_by_id: 190057,
      cited_by_type: "POST",
      post_id: 190059,
      user_id: 1413053
    }
  ]
  into:
  [
    %{
      block_linker: ["block-zByQI"],
      cited_by_id: 190058,
      cited_by_type: "POST",
      post_id: 190059,
      user_id: 1413053
    },
    %{
      block_linker: ["block-zByQI", "block-ZgKJs"],
      cited_by_id: 190057,
      cited_by_type: "POST",
      post_id: 190059,
      user_id: 1413053
    },
  ]
  """
  defp merge_same_cited_article_block(cited_contents) do
    cited_contents
    |> Enum.chunk_by(& &1.cited_by_id)
    |> Enum.map(fn content_by_group ->
      Enum.reduce(content_by_group, fn content, acc ->
        Map.merge(content, %{block_linker: content.block_linker ++ acc.block_linker})
      end)
    end)
  end

  defp get_cited_contents_per_block(article, %{
         "id" => block_id,
         "data" => %{"text" => text}
       }) do
    #
    links_in_block = Floki.find(text, "a[href]")

    Enum.reduce(links_in_block, [], fn link, acc ->
      with {:ok, cited_article} <- parse_cited_article(link) do
        List.insert_at(acc, 0, shape_cited_content(article, cited_article, block_id))
      else
        {:error, _} -> acc
      end
    end)
    |> Enum.uniq()
  end

  defp shape_cited_content(article, cited_article, block_id) do
    thread = article.meta.thread |> String.downcase() |> String.to_atom()
    {:ok, info} = match(thread)

    %{
      cited_by_id: cited_article.id,
      cited_by_type: cited_article.meta.thread,
      block_linker: [block_id],
      user_id: article.author.user.id
    }
    |> Map.put(info.foreign_key, article.id)
  end

  defp parse_cited_article({"a", attrs, _}) do
    with {:ok, link} <- get_link(Enum.find(attrs, fn {a, v} -> a == "href" end)),
         true <- is_valid_article_link?(link) do
      get_cited_article(link)
    end
  end

  defp get_link({"href", link}), do: {:ok, link}
  defp get_link(_), do: {:error, "invalid fmt"}

  defp is_valid_article_link?(url) do
    Enum.any?(@valid_article_prefix, &String.starts_with?(url, &1))
  end

  # get cited article from url
  # e.g: https://coderplanets.com/post/189993 -> ORM.find(Post, 189993)
  defp get_cited_article(url) do
    %{path: path} = URI.parse(url)
    path_list = path |> String.split("/")
    thread = path_list |> Enum.at(1) |> String.downcase() |> String.to_atom()
    article_id = path_list |> Enum.at(2)

    with {:ok, info} <- match(thread) do
      ORM.find(info.model, article_id)
    end
  end

  defp run_tasks(:mention) do
    #
  end

  # 还是单抽一个模块吧
  defp run_tasks(:danger_words) do
    # title & body
  end

  defp parse_blocks(%{body: body} = article) do
    with {:ok, body_map} <- Jason.decode(body) do
      #
    end
  end
end
