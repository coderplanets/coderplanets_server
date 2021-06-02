defmodule GroupherServer.CMS.Helper.Loader do
  @moduledoc """
  dataloader for cms context
  """
  import Ecto.Query, warn: false

  alias GroupherServer.{CMS, Repo}

  alias CMS.{
    Author,
    CommunityEditor,
    CommunitySubscriber,
    CommunityThread,
    PostComment,
    PostCommentLike,
    PostCommentReply
  }

  alias Helper.QueryBuilder

  def data, do: Dataloader.Ecto.new(Repo, query: &query/2)

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
    |> load_inner_replies(filter)
  end

  @doc """
  load replies of the given comment
  TODO: remove
  """
  defp load_inner_replies(queryable, filter) do
    queryable
    |> QueryBuilder.filter_pack(filter)
    |> join(:inner, [c], r in assoc(c, :reply))
    |> select([c, r], r)
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

  # def query({"articles_comments_upvotes", ArticleCommentUpvote}, %{
  #       viewer_did: _,
  #       cur_user: cur_user
  #     }) do
  #   ArticleCommentUpvote |> where([f], f.user_id == ^cur_user.id)
  # end

  # default loader
  def query(queryable, _args) do
    queryable
  end
end
