defmodule GroupherServer.CMS.Delegate.CiteTasks do
  @moduledoc """
  run tasks in every article blocks if need

  current task: "cite link" and "mention"

  ## cite link

  我被站内哪些文章或评论引用了，是值得关注的事
  我引用了谁不重要，帖子里链接已经表明了, 这和 github issue 的双向链接不一样，因为一般不需要关注这个
  帖子是否解决，是否被 merge 等状态。

  基本结构：

  cited_thread, cited_article_id, [xxx_article]_id, [block_id, block2_id],

  POST post_333 -> cited_article_333, [block_id, block2_id]]

  cited_type, cited_content_id, [contents]_id, [block_id, cited_block_id],

  cited_type: thread or comment
  content: article or comment
  # cited_article_comment_id, [xxx_article]_id, [block_id, block2_id, ...],
  """

  import Ecto.Query, warn: false
  import Helper.Utils, only: [get_config: 2, thread_of_article: 1, done: 1]
  import GroupherServer.CMS.Helper.Matcher
  import Helper.ErrorCode

  alias GroupherServer.{CMS, Repo}
  alias CMS.Model.{CitedContent, Comment}
  alias Helper.ORM

  alias Ecto.Multi

  @site_host get_config(:general, :site_host)
  @article_threads get_config(:article, :threads)
  @valid_article_prefix Enum.map(@article_threads, &"#{@site_host}/#{&1}/")

  def handle(%{body: body} = content) do
    with {:ok, %{"blocks" => blocks}} <- Jason.decode(body),
         content <- preload_content_author(content) do
      Multi.new()
      |> Multi.run(:delete_all_cited_contents, fn _, _ ->
        delete_all_cited_contents(content)
      end)
      |> Multi.run(:update_cited_info, fn _, _ ->
        blocks
        |> Enum.reduce([], &(&2 ++ parse_cited_info_per_block(content, &1)))
        |> merge_same_cited_article_block
        |> update_cited_info
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  def preload_content_author(%Comment{} = comment), do: comment
  def preload_content_author(article), do: Repo.preload(article, author: :user)

  # delete all records before insert_all, this will dynamiclly update
  # those cited info when update article
  # 插入引用记录之前先全部清除，这样可以在更新文章的时候自动计算引用信息
  defp delete_all_cited_contents(%Comment{} = comment) do
    query = from(c in CitedContent, where: c.comment_id == ^comment.id)
    ORM.delete_all(query, :if_exist)
  end

  defp delete_all_cited_contents(article) do
    with {:ok, thread} <- thread_of_article(article),
         {:ok, info} <- match(thread) do
      query = from(c in CitedContent, where: field(c, ^info.foreign_key) == ^article.id)

      ORM.delete_all(query, :if_exist)
    end
  end

  # batch insert CitedContent record and update citing count
  defp update_cited_info(cited_contents) do
    # see: https://github.com/elixir-ecto/ecto/issues/1932#issuecomment-314083252
    clean_cited_contents =
      cited_contents
      |> Enum.map(&(&1 |> Map.merge(%{inserted_at: &1.citing_time, updated_at: &1.citing_time})))
      |> Enum.map(&Map.delete(&1, :cited_content))
      |> Enum.map(&Map.delete(&1, :citing_time))

    case {0, nil} !== Repo.insert_all(CitedContent, clean_cited_contents) do
      true -> update_citing_count(cited_contents)
      false -> {:error, "insert cited content error"}
    end
  end

  defp update_citing_count(cited_contents) do
    Enum.all?(cited_contents, fn content ->
      count_query = from(c in CitedContent, where: c.cited_by_id == ^content.cited_by_id)
      count = Repo.aggregate(count_query, :count)

      cited_content = content.cited_content
      meta = Map.merge(cited_content.meta, %{citing_count: count})

      case cited_content |> ORM.update_meta(meta) do
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
      cited_content: #loaded,
      post_id: 190059,
      user_id: 1413053
    }
    ...
  ]
  """
  defp parse_cited_info_per_block(content, %{"id" => block_id, "data" => %{"text" => text}}) do
    links = Floki.find(text, "a[href]")

    do_parse_cited_info(content, block_id, links)
  end

  # links Floki parsed fmt
  # content means both article and comment
  # e.g:
  # [{"a", [{"href", "https://coderplanets.com/post/195675"}], []},]
  defp do_parse_cited_info(content, block_id, links) do
    Enum.reduce(links, [], fn link, acc ->
      case parse_valid_cited(content.id, link) do
        {:ok, cited} -> List.insert_at(acc, 0, shape_cited(content, cited, block_id))
        _ -> acc
      end
    end)
    |> Enum.uniq()
  end

  # parse cited with check if citing link is point to itself
  defp parse_valid_cited(content_id, link) do
    with {:ok, cited} <- parse_cited(link),
         %{content: content} <- cited do
      case content.id !== content_id do
        true -> {:ok, cited}
        false -> {:error, "citing itself"}
      end
    end
  end

  # cite article in comment
  # 在评论中引用文章
  defp shape_cited(%Comment{} = comment, %{type: :article, content: cited}, block_id) do
    %{
      cited_by_id: cited.id,
      cited_by_type: cited.meta.thread,
      comment_id: comment.id,
      block_linker: [block_id],
      user_id: comment.author_id,
      # extra fields for next-step usage
      # used for updating citing_count, avoid load again
      cited_content: cited,
      # for later insert all
      citing_time: comment.updated_at |> DateTime.truncate(:second)
    }
  end

  # cite comment in comment
  # 评论中引用评论
  defp shape_cited(%Comment{} = comment, %{type: :comment, content: cited}, block_id) do
    %{
      cited_by_id: cited.id,
      cited_by_type: "COMMENT",
      comment_id: comment.id,
      block_linker: [block_id],
      user_id: comment.author_id,
      # extra fields for next-step usage
      # used for updating citing_count, avoid load again
      cited_content: cited,
      # for later insert all
      citing_time: comment.updated_at |> DateTime.truncate(:second)
    }
  end

  # cite article in article
  # 文章之间相互引用
  defp shape_cited(article, %{type: :article, content: cited}, block_id) do
    {:ok, thread} = thread_of_article(article)
    {:ok, info} = match(thread)

    %{
      cited_by_id: cited.id,
      cited_by_type: cited.meta.thread,
      block_linker: [block_id],
      user_id: article.author.user.id,
      # extra fields for next-step usage
      # used for updating citing_count, avoid load again
      cited_content: cited,
      # for later insert all
      citing_time: article.updated_at |> DateTime.truncate(:second)
    }
    |> Map.put(info.foreign_key, article.id)
  end

  # cite comment in article
  # 文章中引用评论
  defp shape_cited(article, %{type: :comment, content: cited}, block_id) do
    {:ok, thread} = thread_of_article(article)
    {:ok, info} = match(thread)

    %{
      cited_by_id: cited.id,
      cited_by_type: "COMMENT",
      block_linker: [block_id],
      user_id: article.author.user.id,
      # extra fields for next-step usage
      # used for updating citing_count, avoid load again
      cited_content: cited,
      # for later insert all
      citing_time: article.updated_at |> DateTime.truncate(:second)
    }
    |> Map.put(info.foreign_key, article.id)
  end

  # 要考虑是否有 comment_id 的情况，如果有，那么 就应该 load comment 而不是 article
  defp parse_cited({"a", attrs, _}) do
    with {:ok, link} <- parse_link(attrs),
         true <- is_site_article_link?(link) do
      # IO.inspect(link, label: "parse link")
      # IO.inspect(is_comment_link?(link), label: "is_comment_link")

      case is_comment_link?(link) do
        true -> load_cited_comment_from_url(link)
        false -> load_cited_article_from_url(link)
      end
    end
  end

  @doc """
  parse link from Floki parse result

  e.g:
  [{"href", "https://coderplanets.com/post/190220", "bla", "bla"}] ->
  {:ok, "https://coderplanets.com/post/190220"}
  """
  defp parse_link(attrs) do
    with {"href", link} <- Enum.find(attrs, fn {a, _v} -> a == "href" end) do
      {:ok, link}
    else
      _ -> {:error, "invalid fmt"}
    end
  end

  # 检测是否是站内文章的链接
  defp is_site_article_link?(url) do
    Enum.any?(@valid_article_prefix, &String.starts_with?(url, &1))
  end

  defp is_comment_link?(url) do
    with %{query: query} <- URI.parse(url) do
      not is_nil(query) and String.starts_with?(query, "comment_id=")
    end
  end

  defp load_cited_comment_from_url(url) do
    %{query: query} = URI.parse(url)

    try do
      comment_id = URI.decode_query(query) |> Map.get("comment_id")

      with {:ok, comment} <- ORM.find(Comment, comment_id) do
        {:ok, %{type: :comment, content: comment}}
      end
    rescue
      _ -> {:error, "load comment error"}
    end
  end

  # get cited article from url
  # e.g: https://coderplanets.com/post/189993 -> ORM.find(Post, 189993)
  defp load_cited_article_from_url(url) do
    %{path: path} = URI.parse(url)
    path_list = path |> String.split("/")
    thread = path_list |> Enum.at(1) |> String.downcase() |> String.to_atom()
    article_id = path_list |> Enum.at(2)

    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      {:ok, %{type: :article, content: article}}
    end
  end

  defp result({:ok, %{update_cited_info: result}}), do: {:ok, result}

  defp result({:error, :update_cited_info, _result, _steps}) do
    {:error, [message: "cited article", code: ecode(:cite_artilce)]}
  end
end
