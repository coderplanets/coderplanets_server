defmodule GroupherServer.CMS.Utils.Loader do
  @moduledoc """
  dataloader for cms context
  """
  import Ecto.Query, warn: false

  alias GroupherServer.{CMS, Repo}
  alias CMS.Repo, as: CMSRepo

  alias CMS.{
    Author,
    ArticleCommentUpvote,
    CommunityEditor,
    CommunitySubscriber,
    CommunityThread,
    # POST
    Post,
    PostComment,
    PostCommentLike,
    PostCommentReply,
    # JOB
    Job
    # JobStar,
    # Repo,
  }

  alias Helper.QueryBuilder

  def data, do: Dataloader.Ecto.new(Repo, query: &query/2, run_batch: &run_batch/5)

  # Big thanks: https://elixirforum.com/t/grouping-error-in-absinthe-dadaloader/13671/2
  # see also: https://github.com/absinthe-graphql/dataloader/issues/25
  def run_batch(Post, content_query, :posts_count, community_ids, repo_opts) do
    query_content_counts(content_query, community_ids, repo_opts)
  end

  def run_batch(Job, content_query, :jobs_count, community_ids, repo_opts) do
    query_content_counts(content_query, community_ids, repo_opts)
  end

  def run_batch(CMSRepo, content_query, :repos_count, community_ids, repo_opts) do
    query_content_counts(content_query, community_ids, repo_opts)
  end

  defp query_content_counts(content_query, community_ids, repo_opts) do
    query =
      from(
        content in content_query,
        join: c in assoc(content, :communities),
        where: c.id in ^community_ids,
        group_by: c.id,
        select: {c.id, [count(content.id)]}
      )

    results =
      query
      |> Repo.all(repo_opts)
      |> Map.new()

    for id <- community_ids, do: Map.get(results, id, [0])
  end

  def run_batch(PostComment, comment_query, :cp_count, post_ids, repo_opts) do
    results =
      comment_query
      |> join(:inner, [c], a in assoc(c, :author))
      # |> distinct([c, a], a.id)
      |> group_by([c, a], a.id)
      |> group_by([c, a], c.post_id)
      |> select([c, a], {c.post_id, count(a.id)})
      |> Repo.all(repo_opts)
      |> Enum.group_by(fn {x, _} -> x end)
      |> Enum.map(fn {x, y} -> {x, [length(y)]} end)
      |> Map.new()

    for id <- post_ids, do: Map.get(results, id, [0])
  end

  def query(Author, _args) do
    from(a in Author, join: u in assoc(a, :user), select: u)
  end

  def query({"communities_threads", CommunityThread}, _info) do
    from(
      ct in CommunityThread,
      join: t in assoc(ct, :thread),
      order_by: [asc: t.index],
      select: t
    )
  end

  def query({"communities_subscribers", CommunitySubscriber}, args) do
    CommunitySubscriber |> QueryBuilder.members_pack(args)
  end

  def query({"communities_editors", CommunityEditor}, args) do
    CommunityEditor |> QueryBuilder.members_pack(args)
  end

  # ------- post comments ------
  @doc """
  get unique participators join in comments
  """
  # NOTE: this is NOT the right solution
  # should use WINDOW function
  # see https://github.com/coderplanets/coderplanets_server/issues/16
  def query({"posts_comments", PostComment}, %{filter: _filter, unique: true}) do
    PostComment
    |> join(:inner, [c], a in assoc(c, :author))
    # NOTE:  this distinct not working in production env, so the uniq logic is move to
    # cut_participators.ex middleware, when the data is large, will cause performace issue
    # |> distinct([c, a], a.id)
    |> select([c, a], a)
  end

  def query({"posts_comments", PostComment}, %{count: _, unique: true}) do
    PostComment
    |> join(:inner, [c], a in assoc(c, :author))
    |> distinct([c, a], a.id)
    |> group_by([c, a], a.id)
    |> group_by([c, a], c.post_id)
    |> select([c, a], count(c.id))
  end

  def query({"posts_comments", PostComment}, %{count: _}) do
    PostComment
    |> group_by([c], c.post_id)
    |> select([c], count(c.id))
  end

  def query({"posts_comments", PostComment}, %{filter: filter}) do
    PostComment
    |> QueryBuilder.filter_pack(filter)
  end

  def query({"posts_comments_replies", PostCommentReply}, %{count: _}) do
    PostCommentReply
    |> group_by([c], c.post_comment_id)
    |> select([c], count(c.id))
  end

  def query({"posts_comments_replies", PostCommentReply}, %{filter: filter}) do
    PostCommentReply
    |> QueryBuilder.load_inner_replies(filter)
  end

  def query({"posts_comments_replies", PostCommentReply}, %{reply_to: _}) do
    PostCommentReply
    |> join(:inner, [c], r in assoc(c, :post_comment))
    |> select([c, r], r)
  end

  def query({"posts_comments_likes", PostCommentLike}, %{count: _}) do
    PostCommentLike
    |> group_by([f], f.post_comment_id)
    |> select([f], count(f.id))
  end

  def query({"posts_comments_likes", PostCommentLike}, %{viewer_did: _, cur_user: cur_user}) do
    PostCommentLike |> where([f], f.user_id == ^cur_user.id)
  end

  def query({"posts_comments_likes", PostCommentLike}, %{filter: _filter} = args) do
    PostCommentLike
    |> QueryBuilder.members_pack(args)
  end

  def query({"articles_comments_upvotes", ArticleCommentUpvote}, %{
        viewer_did: _,
        cur_user: cur_user
      }) do
    ArticleCommentUpvote |> where([f], f.user_id == ^cur_user.id)
  end

  # default loader
  def query(queryable, _args) do
    queryable
  end
end
