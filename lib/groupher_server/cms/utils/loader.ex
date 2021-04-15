defmodule GroupherServer.CMS.Utils.Loader do
  @moduledoc """
  dataloader for cms context
  """
  import Ecto.Query, warn: false

  alias GroupherServer.{CMS, Repo}
  alias CMS.Repo, as: CMSRepo

  alias CMS.{
    Author,
    CommunityEditor,
    CommunitySubscriber,
    CommunityThread,
    # POST
    Post,
    PostViewer,
    PostComment,
    PostCommentDislike,
    PostCommentLike,
    PostCommentReply,
    PostFavorite,
    PostStar,
    # JOB
    Job,
    JobViewer,
    JobFavorite,
    # JobStar,
    # Repo,
    RepoViewer,
    RepoFavorite,
    RepoComment,
    RepoCommentReply,
    RepoCommentLike,
    RepoCommentDislike
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

  def query({"posts_viewers", PostViewer}, %{cur_user: cur_user}) do
    PostViewer |> where([pv], pv.user_id == ^cur_user.id)
  end

  def query({"jobs_viewers", JobViewer}, %{cur_user: cur_user}) do
    JobViewer |> where([pv], pv.user_id == ^cur_user.id)
  end

  def query({"repos_viewers", RepoViewer}, %{cur_user: cur_user}) do
    RepoViewer |> where([pv], pv.user_id == ^cur_user.id)
  end

  @doc """
  handle query:
  1. bacic filter of pagi,when,sort ...
  2. count of the reactions
  3. check is viewer reacted
  """
  def query({"posts_favorites", PostFavorite}, args) do
    PostFavorite |> QueryBuilder.members_pack(args)
  end

  def query({"posts_stars", PostStar}, args) do
    PostStar |> QueryBuilder.members_pack(args)
  end

  def query({"jobs_favorites", JobFavorite}, args) do
    JobFavorite |> QueryBuilder.members_pack(args)
  end

  def query({"repos_favorites", RepoFavorite}, args) do
    RepoFavorite |> QueryBuilder.members_pack(args)
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

    # |> select([c, a], %{
    #   rankid: rank() |> over(partition_by: c.inserted_at),
    #   id: a.id,
    #   nickname: a.nickname
    # })
    # |> windows([rankid: [partition_by: c.inserted_at]])
    # |> where([c, a], a.no < 3)
    # |> select([c, a], rank() |>  over(partition_by: c.inserted_at))
    # |> select([c, a], %{
    #     nickname: a.nickname,

    # working raw sql
    # select * from(
    #     select rank() over(partition by cid order by pinserted_at desc) as r, * from(
    #         select c.id as cid,
    #  c.body as cbody,
    #  p.inserted_at as pinserted_at,
    #  u.* from "cms_posts" as c join "posts_comments" as p on c.id= p.post_id join "users" as u on p.author_id= u.id) as view
    # ) as v where r<= 3;

    # backup ->
    # PostComment
    # |> QueryBuilder.filter_pack(filter)
    # |> join(:inner, [c], a in assoc(c, :author))
    # |> distinct([c, a], a.id)
    # |> select([c, a], a)
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

  def query({"posts_comments_dislikes", PostCommentDislike}, %{count: _}) do
    PostCommentDislike
    |> group_by([f], f.post_comment_id)
    |> select([f], count(f.id))
  end

  # component dislikes
  def query({"posts_comments_dislikes", PostCommentDislike}, %{viewer_did: _, cur_user: cur_user}) do
    PostCommentDislike |> where([f], f.user_id == ^cur_user.id)
  end

  def query({"posts_comments_dislikes", PostCommentDislike}, %{filter: _filter} = args) do
    PostCommentDislike
    |> QueryBuilder.members_pack(args)
  end

  # --- repo comments ------
  def query({"repos_comments", RepoComment}, %{filter: _filter, unique: true}) do
    RepoComment
    # |> QueryBuilder.filter_pack(filter)
    |> join(:inner, [c], a in assoc(c, :author))
    |> distinct([c, a], a.id)
    |> select([c, a], a)
  end

  def query({"repos_comments", RepoComment}, %{count: _, unique: true}) do
    RepoComment
    |> join(:inner, [c], a in assoc(c, :author))
    |> distinct([c, a], a.id)
    |> group_by([c, a], a.id)
    |> group_by([c, a], c.repo_id)
    |> select([c, a], count(c.id))
  end

  def query({"repos_comments", RepoComment}, %{count: _}) do
    RepoComment
    |> group_by([c], c.repo_id)
    |> select([c], count(c.id))
  end

  def query({"repos_comments_replies", RepoCommentReply}, %{count: _}) do
    RepoCommentReply
    |> group_by([c], c.repo_comment_id)
    |> select([c], count(c.id))
  end

  def query({"repos_comments_replies", RepoCommentReply}, %{filter: filter}) do
    RepoCommentReply
    |> QueryBuilder.load_inner_replies(filter)
  end

  def query({"repos_comments_replies", RepoCommentReply}, %{reply_to: _}) do
    RepoCommentReply
    |> join(:inner, [c], r in assoc(c, :repo_comment))
    |> select([c, r], r)
  end

  def query({"repos_comments_likes", RepoCommentLike}, %{count: _}) do
    RepoCommentLike
    |> group_by([f], f.repo_comment_id)
    |> select([f], count(f.id))
  end

  def query({"repos_comments_likes", RepoCommentLike}, %{viewer_did: _, cur_user: cur_user}) do
    RepoCommentLike |> where([f], f.user_id == ^cur_user.id)
  end

  def query({"repos_comments_likes", RepoCommentLike}, %{filter: _filter} = args) do
    RepoCommentLike
    |> QueryBuilder.members_pack(args)
  end

  def query({"repos_comments_dislikes", RepoCommentDislike}, %{count: _}) do
    RepoCommentDislike
    |> group_by([f], f.repo_comment_id)
    |> select([f], count(f.id))
  end

  # component dislikes
  def query({"repos_comments_dislikes", RepoCommentDislike}, %{
        viewer_did: _,
        cur_user: cur_user
      }) do
    RepoCommentDislike |> where([f], f.user_id == ^cur_user.id)
  end

  def query({"repos_comments_dislikes", RepoCommentDislike}, %{filter: _filter} = args) do
    RepoCommentDislike
    |> QueryBuilder.members_pack(args)
  end

  # --- repo ------

  # default loader
  def query(queryable, _args), do: queryable
end
