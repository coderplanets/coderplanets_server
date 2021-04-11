defmodule GroupherServer.CMS.Delegate.ArticleComment do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]

  import ShortMaps

  alias Helper.{ORM, QueryBuilder}
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User
  alias CMS.{ArticleComment, ArticleCommentUpvote, Post, Job}
  alias Ecto.Multi

  # the limit of latest participators stored in article's comment_participator
  @max_participator_count 10

  @doc """
  list paged article comments
  """
  def list_article_comments(thread, article_id, %{page: page, size: size} = filters) do
    with {:ok, thread_query} <- match(thread, :query, article_id) do
      ArticleComment
      |> where(^thread_query)
      |> QueryBuilder.filter_pack(filters)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  defp match(:post, :query, id), do: {:ok, dynamic([c], c.post_id == ^id)}
  defp match(:job, :query, id), do: {:ok, dynamic([c], c.job_id == ^id)}

  @doc """
  Creates a comment for psot, job ...
  """
  def write_comment(
        thread,
        article_id,
        content,
        %User{id: user_id} = user
      ) do
    with {:ok, info} <- match(thread),
         # make sure the article exsit
         # author is passed by middleware, it's exsit for sure
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:write_comment, fn _, _ ->
        args = %{author_id: user_id, body_html: content} |> Map.put(info.foreign_key, article.id)
        ArticleComment |> ORM.create(args)
      end)
      |> Multi.run(:add_participator, fn _, _ ->
        add_participator_to_article(article, user)
      end)
      # |> Multi.run(:mention_users, fn _, %{create_comment: comment} ->
      #   Delivery.mention_from_comment(community, thread, content, comment, args, user)
      #   {:ok, :pass}
      # end)
      |> Repo.transaction()
      |> write_comment_result()
    end
  end

  defp write_comment_result({:ok, %{write_comment: result}}), do: {:ok, result}

  defp write_comment_result({:error, :create_comment, result, _steps}) do
    {:error, result}
  end

  defp write_comment_result({:error, :add_participator, result, _steps}) do
    {:error, result}
  end

  def upvote_comment(comment_id, %User{id: user_id}) do
    # make sure the comment exsit
    # TODO: make sure the comment is not deleted yet
    with {:ok, comment} <- ORM.find(ArticleComment, comment_id) do
      args = %{article_comment_id: comment.id, user_id: user_id}
      ArticleCommentUpvote |> ORM.create(args)
    end
  end

  # add participator to article-like content (Post, Job ...)
  defp add_participator_to_article(%Post{} = article, %User{} = user) do
    new_comment_participators =
      article.comment_participators
      |> List.insert_at(0, user)
      |> Enum.uniq()
      |> Enum.slice(0, @max_participator_count)

    article
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:comment_participators, new_comment_participators)
    |> Repo.update()
  end

  defp match(:post) do
    {:ok, %{model: Post, foreign_key: :post_id}}
  end

  defp match(:job) do
    {:ok, %{model: Job, foreign_key: :job_id}}
  end

  # defp do_create_comment(thread, action, content, body, user) do
  #   next_floor = get_next_floor(thread, action.reactor, content.id)

  #   attrs = %{
  #     author_id: user.id,
  #     body: body,
  #     floor: next_floor
  #   }

  #   attrs = merge_comment_attrs(thread, attrs, content.id)

  #   action.reactor |> ORM.create(attrs)
  # end
end
