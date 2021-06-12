defmodule GroupherServer.CMS.Delegate.BlockTasks do
  @moduledoc """
  run tasks in every article blocks if need
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [get_config: 2, thread_of_article: 1, done: 1]
  import GroupherServer.CMS.Helper.Matcher
  import Helper.ErrorCode

  alias GroupherServer.{CMS, Repo}
  alias CMS.Model.CitedContent
  alias Helper.ORM

  alias Ecto.Multi

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
      # run_tasks(:mention, article, body_map["blocks"])
    end
  end

  defp run_tasks(:cite, article, blocks) do
    article = article |> Repo.preload(author: :user)

    Multi.new()
    |> Multi.run(:delete_all_cited_contents, fn _, _ ->
      delete_all_cited_contents(article)
    end)
    |> Multi.run(:update_cited_info, fn _, _ ->
      blocks
      |> Enum.reduce([], &(&2 ++ parse_cited_info_per_block(article, &1)))
      |> merge_same_cited_article_block
      |> update_cited_info
    end)
    |> Repo.transaction()
    |> result()
  end

  # delete all records before insert_all, this will dynamiclly update
  # those cited info when update article
  # 插入引用记录之前先全部清除，这样可以在更新文章的时候自动计算引用信息
  defp delete_all_cited_contents(article) do
    with {:ok, thread} <- thread_of_article(article),
         {:ok, info} <- match(thread) do
      query = from(c in CitedContent, where: field(c, ^info.foreign_key) == ^article.id)

      ORM.delete_all(query, :if_exist)
    end
  end

  # defp batch_done

  defp update_cited_info(cited_contents) do
    clean_cited_contents = Enum.map(cited_contents, &Map.delete(&1, :cited_article))
    IO.inspect(clean_cited_contents, label: "clean_cited_contents")

    with true <- {0, nil} !== Repo.insert_all(CitedContent, clean_cited_contents) do
      update_citing_count(cited_contents)
    else
      _ -> {:error, "insert cited content error"}
    end
  end

  defp update_citing_count(cited_contents) do
    Enum.all?(cited_contents, fn content ->
      count_query = from(c in CitedContent, where: c.cited_by_id == ^content.cited_by_id)
      count = Repo.aggregate(count_query, :count)

      cited_article = content.cited_article
      meta = Map.merge(cited_article.meta, %{citing_count: count})

      case cited_article |> ORM.update_meta(meta) do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end)
    |> done
  end

  @doc """
  merge same cited article in different blocks
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
    |> Enum.reduce([], fn content, acc ->
      case Enum.find_index(acc, &(&1.cited_by_id == content.cited_by_id)) do
        nil ->
          acc ++ [content]

        index ->
          List.update_at(
            acc,
            index,
            &Map.merge(&1, %{block_linker: &1.block_linker ++ content.block_linker})
          )
      end
    end)
  end

  @doc """
  return fmt like:
  [
    %{
      block_linker: ["block-ZgKJs"],
      cited_by_id: 190057,
      cited_by_type: "POST",
      cited_article: #loaded,
      post_id: 190059,
      user_id: 1413053
    }
    ...
  ]
  """
  defp parse_cited_info_per_block(article, %{
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
    {:ok, thread} = thread_of_article(article)
    {:ok, info} = match(thread)

    %{
      cited_by_id: cited_article.id,
      cited_by_type: cited_article.meta.thread,
      # used for updating citing_count, avoid load again
      cited_article: cited_article,
      block_linker: [block_id],
      user_id: article.author.user.id
    }
    |> Map.put(info.foreign_key, article.id)
  end

  defp parse_cited_article({"a", attrs, _}) do
    with {:ok, link} <- parse_link(attrs),
         true <- is_site_article_link?(link) do
      load_cited_article_from_url(link)
    end
  end

  @doc """
  parse link from Floki parse result

  e.g:
  [{"href", "https://coderplanets.com/post/190220", "bla", "bla"}] ->
  {:ok, "https://coderplanets.com/post/190220"}
  """
  defp parse_link(attrs) do
    with {"href", link} <- Enum.find(attrs, fn {a, v} -> a == "href" end) do
      {:ok, link}
    else
      _ -> {:error, "invalid fmt"}
    end
  end

  # 检测是否是站内文章的链接
  defp is_site_article_link?(url) do
    Enum.any?(@valid_article_prefix, &String.starts_with?(url, &1))
  end

  # get cited article from url
  # e.g: https://coderplanets.com/post/189993 -> ORM.find(Post, 189993)
  defp load_cited_article_from_url(url) do
    %{path: path} = URI.parse(url)
    path_list = path |> String.split("/")
    thread = path_list |> Enum.at(1) |> String.downcase() |> String.to_atom()
    article_id = path_list |> Enum.at(2)

    with {:ok, info} <- match(thread) do
      ORM.find(info.model, article_id)
    end
  end

  defp result({:ok, %{update_cited_info: result}}), do: {:ok, result}

  defp result({:error, :update_cited_info, _result, _steps}) do
    {:error, [message: "cited article", code: ecode(:cite_artilce)]}
  end
end
