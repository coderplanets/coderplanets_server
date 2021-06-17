defmodule GroupherServer.CMS.Delegate.Hooks.Mention do
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
  import GroupherServer.CMS.Delegate.Hooks.Helper, only: [merge_same_block_linker: 2]

  alias GroupherServer.{Accounts, CMS, Repo}
  alias CMS.Model.Comment

  @article_threads get_config(:article, :threads)

  @article_mention_class "cdx-mention"

  def handle(%{body: body} = content) do
    with {:ok, %{"blocks" => blocks}} <- Jason.decode(body),
         content <- preload_author(content) do
      blocks
      |> Enum.reduce([], &(&2 ++ parse_cited_info_per_block(content, &1)))
      |> merge_same_block_linker(:to_user_id)
      |> done
    end
  end

  def preload_author(%Comment{} = comment), do: comment
  def preload_author(article), do: Repo.preload(article, author: :user)

  defp parse_cited_info_per_block(content, %{"id" => block_id, "data" => %{"text" => text}}) do
    mentions = Floki.find(text, ".#{@article_mention_class}")

    do_parse_cited_info_per_block(content, block_id, mentions)
  end

  # links Floki parsed fmt
  # content means both article and comment
  # e.g:
  # [{"a", [{"href", "https://coderplanets.com/post/195675"}], []},]
  defp do_parse_cited_info_per_block(content, block_id, mentions) do
    Enum.reduce(mentions, [], fn mention, acc ->
      case parse_mention_user_id(mention) do
        {:ok, user_id} -> List.insert_at(acc, 0, shape(content, user_id, block_id))
        {:error, _} -> acc
      end
    end)
    |> Enum.uniq()
  end

  # 确保 mention 的用户是存在的
  defp parse_mention_user_id({_, _, [user_login]}) do
    Accounts.get_userid_and_cache(user_login)
  end

  defp shape(%Comment{} = comment, mention_user_id, block_id) do
    # @article_threads |> Enum.find(fn thread -> not is_nil(Map.get(comment, :"#{thread}_id")) end)
    %{
      block_linker: [block_id],
      read: false,
      from_user_id: comment.author_id,
      to_user_id: mention_user_id
    }
  end

  defp shape(article, to_user_id, block_id) do
    %{
      type: thread_of_article(article),
      title: article.title,
      article_id: article.id,
      block_linker: [block_id],
      read: false,
      from_user_id: article.author.user_id,
      to_user_id: to_user_id
    }
  end
end
