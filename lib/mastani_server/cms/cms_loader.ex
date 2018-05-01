defmodule MastaniServer.CMS.Loader do
  import Ecto.Query, warn: false

  alias MastaniServer.Repo
  alias Helper.QueryBuilder

  alias MastaniServer.CMS.{
    Author,
    Post,
    PostComment,
    PostFavorite,
    PostStar,
    CommunitySubscriber,
    CommunityEditor,
    CommunityThread,
    PostCommentReply,
    PostCommentLike,
    PostCommentDislike
  }

  def data(), do: Dataloader.Ecto.new(Repo, query: &query/2, run_batch: &run_batch/5)

  # Big thanks: https://elixirforum.com/t/grouping-error-in-absinthe-dadaloader/13671/2
  # see also: https://github.com/absinthe-graphql/dataloader/issues/25
  def run_batch(Post, post_query, :posts_count, community_ids, repo_opts) do
    query =
      from(
        p in post_query,
        join: c in assoc(p, :communities),
        where: c.id in ^community_ids,
        group_by: c.id,
        select: {c.id, [count(p.id)]}
      )

    results =
      query
      |> Repo.all(repo_opts)
      |> Map.new()

    for id <- community_ids, do: Map.get(results, id, [0])
  end

  def query(Author, _args) do
    # you cannot use preload with select together
    # https://stackoverflow.com/questions/43010352/ecto-select-relations-from-preload
    # see also
    # https://github.com/elixir-ecto/ecto/issues/1145
    from(a in Author, join: u in assoc(a, :user), select: u)
  end

  def query({"communities_threads", CommunityThread}, _info) do
    from(ct in CommunityThread, join: t in assoc(ct, :thread), select: t)
  end

  def query({"posts_comments", PostComment}, %{filter: filter}) do
    PostComment |> QueryBuilder.filter_pack(filter)
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

  def query({"communities_subscribers", CommunitySubscriber}, args) do
    CommunitySubscriber |> QueryBuilder.members_pack(args)
  end

  def query({"communities_editors", CommunityEditor}, args) do
    CommunityEditor |> QueryBuilder.members_pack(args)
  end

  # for comments replies, likes, repliesCount, likesCount...
  def query({"posts_comments_replies", PostCommentReply}, %{count: _}) do
    PostCommentReply
    |> group_by([c], c.post_comment_id)
    |> select([c], count(c.id))
  end

  def query({"posts_comments_replies", PostCommentReply}, %{filter: filter}) do
    PostCommentReply
    |> QueryBuilder.filter_pack(filter)
    |> join(:inner, [c], r in assoc(c, :reply))
    |> select([c, r], r)
  end

  def query({"posts_comments_replies", PostCommentReply}, %{reply_to: _}) do
    IO.inspect(PostCommentReply, label: 'hello fuc')

    PostCommentReply
    # |> QueryBuilder.filter_pack(filter)
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

  # default loader
  def query(queryable, _args) do
    # IO.inspect(queryable, label: "default loader")
    queryable
  end
end
