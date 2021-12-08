defmodule GroupherServer.CMS.Delegate.Hooks.Cite do
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

  cited_type, cited_artiment_id, [contents]_id, [block_id, cited_block_id],

  cited_type: thread or comment
  artiment: article or comment
  # cited_comment_id, [xxx_article]_id, [block_id, block2_id, ...],

  注意 cited_by_type 不能命名为 cited_by_thread

  因为 cited_by_thread 无法表示这样的语义:
  # 某评论被 post 以 comment link 的方式引用了
  """

  import Ecto.Query, warn: false
  import Helper.Utils, only: [get_config: 2]

  import GroupherServer.CMS.Helper.Matcher
  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1, thread_of: 1]
  import GroupherServer.CMS.Delegate.Hooks.Helper, only: [merge_same_block_linker: 2]

  import Helper.ErrorCode

  alias GroupherServer.{CMS, Repo}
  alias CMS.Delegate.CitedArtiment
  alias CMS.Model.Comment

  alias Helper.ORM
  alias Ecto.Multi

  @site_host get_config(:general, :site_host)
  @article_threads get_config(:article, :threads)
  @valid_article_prefix Enum.map(@article_threads, &"#{@site_host}/#{&1}/")

  def handle(%{body: body} = artiment) when not is_nil(body) do
    with {:ok, %{"blocks" => blocks}} <- Jason.decode(body),
         {:ok, artiment} <- preload_author(artiment) do
      Multi.new()
      |> Multi.run(:delete_all_cited_artiments, fn _, _ ->
        CitedArtiment.batch_delete_by(artiment)
      end)
      |> Multi.run(:update_cited_info, fn _, _ ->
        blocks
        |> Enum.reduce([], &(&2 ++ parse_cited_per_block(artiment, &1)))
        |> merge_same_block_linker(:cited_by_id)
        |> CitedArtiment.batch_insert()
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  def handle(%{document: _document} = article) do
    body = Repo.preload(article, :document) |> get_in([:document, :body])
    article = article |> Map.put(:body, body)
    handle(article)
  end

  @doc """
  return fmt like:
  [
    %{
      block_linker: ["block-ZgKJs"],
      cited_by_id: 190057,
      cited_by_type: :post,
      artiment: #loaded,
      post_id: 190059,
      user_id: 1413053
    }
    ...
  ]
  """
  defp parse_cited_per_block(artiment, %{"id" => block_id, "data" => %{"text" => text}}) do
    links = Floki.find(text, "a[href]")

    parse_links_in_block(artiment, block_id, links)
  end

  # links Floki parsed fmt
  # artiment means both article and comment
  # e.g:
  # [{"a", [{"href", "https://coderplanets.com/post/195675"}], []},]
  defp parse_links_in_block(artiment, block_id, links) do
    Enum.reduce(links, [], fn link, acc ->
      case parse_valid_cited(artiment.id, link) do
        {:ok, cited} -> List.insert_at(acc, 0, shape(artiment, cited, block_id))
        _ -> acc
      end
    end)
    |> Enum.uniq()
  end

  # parse cited with check if citing link is point to itself
  defp parse_valid_cited(content_id, link) do
    with {:ok, cited} <- parse_cited_in_link(link) do
      case not is_citing_itself?(content_id, cited) do
        true -> {:ok, cited}
        false -> {:error, "citing itself, ignored"}
      end
    end
  end

  # return fmt: %{type: :comment | :article, artiment: %Comment{} | Article}
  # 要考虑是否有 comment_id 的情况，如果有，那么 就应该 load comment 而不是 article
  defp parse_cited_in_link({"a", attrs, _}) do
    with {:ok, link} <- parse_link(attrs),
         true <- is_site_article_link?(link) do
      case is_link_for_comment?(link) do
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

  defp load_cited_comment_from_url(url) do
    %{query: query} = URI.parse(url)

    try do
      comment_id = URI.decode_query(query) |> Map.get("comment_id")

      with {:ok, comment} <- ORM.find(Comment, comment_id) do
        {:ok, %{type: :comment, artiment: comment}}
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
      {:ok, %{type: :article, artiment: article}}
    end
  end

  # check if article/comment id is point to itself
  defp is_citing_itself?(content_id, %{artiment: %{id: id}}), do: content_id == id

  # 检测是否是站内文章的链接
  defp is_site_article_link?(url) do
    Enum.any?(@valid_article_prefix, &String.starts_with?(url, &1))
  end

  defp is_link_for_comment?(url) do
    with %{query: query} <- URI.parse(url) do
      not is_nil(query) and String.starts_with?(query, "comment_id=")
    end
  end

  # cite article in comment
  # 在评论中引用文章
  defp shape(%Comment{} = comment, %{type: :article, artiment: cited}, block_id) do
    %{
      cited_by_id: cited.id,
      cited_by_type: cited.meta.thread,
      comment_id: comment.id,
      block_linker: [block_id],
      user_id: comment.author_id,
      # extra fields for next-step usage
      # used for updating citing_count, avoid load again
      artiment: cited,
      # for later insert all
      citing_time: comment.updated_at |> DateTime.truncate(:second)
    }
  end

  # cite comment in comment
  # 评论中引用评论
  defp shape(%Comment{} = comment, %{type: :comment, artiment: cited}, block_id) do
    %{
      cited_by_id: cited.id,
      cited_by_type: :comment,
      comment_id: comment.id,
      block_linker: [block_id],
      user_id: comment.author_id,
      # extra fields for next-step usage
      # used for updating citing_count, avoid load again
      artiment: cited,
      # for later insert all
      citing_time: comment.updated_at |> DateTime.truncate(:second)
    }
  end

  # cite article in article
  # 文章之间相互引用
  defp shape(article, %{type: :article, artiment: cited}, block_id) do
    {:ok, thread} = thread_of(article)
    {:ok, info} = match(thread)

    %{
      cited_by_id: cited.id,
      cited_by_type: cited.meta.thread,
      block_linker: [block_id],
      user_id: article.author.user.id,
      # extra fields for next-step usage
      # used for updating citing_count, avoid load again
      artiment: cited,
      # for later insert all
      citing_time: article.updated_at |> DateTime.truncate(:second)
    }
    |> Map.put(info.foreign_key, article.id)
  end

  # cite comment in article
  # 文章中引用评论
  defp shape(article, %{type: :comment, artiment: cited}, block_id) do
    {:ok, thread} = thread_of(article)
    {:ok, info} = match(thread)

    %{
      cited_by_id: cited.id,
      cited_by_type: :comment,
      block_linker: [block_id],
      user_id: article.author.user.id,
      # extra fields for next-step usage
      # used for updating citing_count, avoid load again
      artiment: cited,
      # for later insert all
      citing_time: article.updated_at |> DateTime.truncate(:second)
    }
    |> Map.put(info.foreign_key, article.id)
  end

  defp result({:ok, %{update_cited_info: result}}), do: {:ok, result}

  defp result({:error, :update_cited_info, _result, _steps}) do
    {:error, [message: "cited article", code: ecode(:cite_artilce)]}
  end
end
