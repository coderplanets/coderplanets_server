defmodule MastaniServer.CMS.Utils.Loader do
  @moduledoc """
  dataloader for cms context
  """
  import Ecto.Query, warn: false

  alias Helper.QueryBuilder
  alias MastaniServer.Repo
  # alias MastaniServer.Accounts
  alias MastaniServer.CMS.{
    Author,
    CommunityEditor,
    CommunitySubscriber,
    CommunityThread,
    # POST
    Post,
    PostComment,
    PostCommentDislike,
    PostCommentLike,
    PostCommentReply,
    PostFavorite,
    PostStar,
    # JOB
    # Job,
    JobFavorite,
    # JobStar,
    JobComment,
    JobCommentReply,
    JobCommentDislike,
    JobCommentLike,
    # Video
    VideoFavorite,
    VideoStar,
    VideoComment,
    VideoCommentReply,
    VideoCommentDislike,
    VideoCommentLike,
    # repo
    RepoComment,
    RepoCommentReply,
    RepoCommentLike,
    RepoCommentDislike
  }

  def data, do: Dataloader.Ecto.new(Repo, query: &query/2, run_batch: &run_batch/5)

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

  def run_batch(PostComment, comment_query, :cp_users, post_ids, repo_opts) do
    # IO.inspect(comment_query, label: "# run_batch # comment_query")

    sq =
      from(
        pc in comment_query,
        join: a in assoc(pc, :author),
        select: %{id: a.id, row_number: fragment("row_number() OVER (PARTITION BY author_id)")}
      )

    query =
      from(
        pc in comment_query,
        join: s in subquery(sq),
        on: s.id == pc.author_id,
        where: s.row_number == 10,
        select: {pc.post_id, s.id}
      )

    # query = comment_query
    # |> join(:inner, [c], a in assoc(c, :author))
    # |> distinct([c, a], c.post_id)
    # |> join(:inner_lateral, [c, a], u in fragment("SELECT * FROM users AS us WHERE us.id = ? LIMIT 1", a.id))
    # |> join(:inner_lateral, [c, a], u in fragment("SELECT * FROM users AS us WHERE us.id > ? LIMIT 1", 100))
    # |> select([c, a, u], {c.post_id, u.id, u.nickname})

    results =
      query
      # |> IO.inspect(label: "before")
      |> Repo.all(repo_opts)
      # |> IO.inspect(label: "geting fuck")
      |> bat_man()

    # results =
    # comment_query
    # |> join(:inner, [c], a in assoc(c, :author))
    # |> group_by([c, a], a.id)
    # |> group_by([c, a], c.post_id)
    # |> select([c, a], {c.post_id, a})
    # ---------
    # |> join(:inner, [c], s in subquery(sq), on: s.id == c.post_id)
    # |> join(:inner, [c], a in subquery(isubquery), c.post_id == 106)
    # |> join(:inner_lateral, [c], a in fragment("SELECT * FROM users AS u WHERE u.id = ? LIMIT 3", c.post_id))
    # |> join(:inner_lateral, [c], a in fragment("SELECT * FROM users WHERE users.id > ? LIMIT 3", 100))
    # |> join(:inner_lateral, [c], a in fragment("SELECT * FROM posts_comments JOIN users ON users.id = ? LIMIT 2", c.author_id))
    # |> join(:inner_lateral, [c], a in fragment("SELECT * FROM posts_comments AS pc WHERE pc.author_id = ? LIMIT 2", 185))
    # |> join(:inner_lateral, [c], a in fragment("SELECT ROW_NUMBER() OVER (PARTITION BY ?) FROM posts_comments AS pc GROUP BY pc.post_id", c.post_id))
    # |> distinct([c, a], c.post_id)
    # |> join(:inner_lateral, [c, a], x in fragment("SELECT * FROM posts_comments JOIN users ON users.id = posts_comments.author_id WHERE post_id = ? LIMIT 2", c.post_id))
    # |> join(:inner_lateral, [c, a], x in fragment("SELECT * FROM posts_comments JOIN users ON users.id = posts_comments.author_id  LIMIT 3"))
    # |> select([c,a,x], {c.post_id, x.author_id})
    # |> select([c,a,x], {c.post_id, a.id})
    # |> where([c, a], a.row_number < 3)
    # |> join(:inner, [c], a in assoc(c, :author))
    # |> join(:inner, [c], a in subquery(isubquery))
    # |> group_by([c, a, x], x.author_id)
    # |> distinct([c, a], a.author_id)
    # |> select([c, a], {c.post_id, a.author_id})
    # |> select([c, a], {c.post_id, fragment("max(?) OVER (PARTITION BY ?)", a.id, a.id)})
    # |> select([c, a], %{post_id: c.post_id, user: fragment("max(?) OVER (PARTITION BY ?)", a.id, a.id)})
    # |> select([c, a], fragment("SELECT ROW_NUMBER() OVER (PARTITION BY ?) FROM cms_authors AS r , ", a.id))
    # |> join([c], c in subquery(sq), on: c.post_id == bq.id)
    # |> having([c, a], count("*") < 10)
    # |> having([c, a], a.id < 180)
    # |> limit(3)
    # |> order_by([p, s], desc: fragment("count(?)", s.id))
    # |> distinct([c, a], a.id)
    # |> Repo.all(repo_opts)
    # |> IO.inspect(label: "get fuck")
    # |> bat_man()

    for id <- post_ids, do: Map.get(results, id, [])
  end

  # TODO: use meta-programing to extract all query below
  # --------------------
  def bat_man(data) do
    # TODO refactor later
    data
    |> Enum.group_by(fn {x, _} -> x end)
    |> Enum.map(fn {x, y} ->
      {x,
       Enum.reduce(y, [], fn kv, acc ->
         {_, v} = kv
         acc ++ [v]
       end)}
    end)
    |> Map.new()
  end

  def query(Author, _args) do
    # you cannot use preload with select together
    # https://stackoverflow.com/questions/43010352/ecto-select-relations-from-preload
    # see also
    # https://github.com/elixir-ecto/ecto/issues/1145
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

  @doc """
  get unique participators join in comments
  """
  def query({"posts_comments", PostComment}, %{filter: filter, unique: true}) do
    # def query({"posts_comments", PostComment}, %{unique: true}) do
    PostComment
    # |> QueryBuilder.members_pack(args)
    |> QueryBuilder.filter_pack(filter)
    |> join(:inner, [c], a in assoc(c, :author))
    |> distinct([c, a], a.id)
    |> select([c, a], a)
  end

  def query({"posts_comments", PostComment}, %{count: _, unique: true}) do
    # TODO: not very familar with SQL, but it has to be 2 group_by to work, check later
    # and the expect count should be the length of reault
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

  # def query({"posts_comments", PostComment}, %{filter: %{first: first}} = filter) do
  def query({"posts_comments", PostComment}, %{filter: filter}) do
    PostComment
    # |> limit(3)
    |> QueryBuilder.filter_pack(filter)
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

  # def query({"jobs_stars", JobStar}, args), do: JobStar |> QueryBuilder.members_pack(args)

  def query({"videos_favorites", VideoFavorite}, args) do
    VideoFavorite |> QueryBuilder.members_pack(args)
  end

  def query({"videos_stars", VideoStar}, args) do
    VideoStar |> QueryBuilder.members_pack(args)
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

  # ---- job comments ------
  def query({"jobs_comments", JobComment}, %{count: _}) do
    JobComment
    |> group_by([c], c.job_id)
    |> select([c], count(c.id))
  end

  def query({"jobs_comments_replies", JobCommentReply}, %{count: _}) do
    JobCommentReply
    |> group_by([c], c.job_comment_id)
    |> select([c], count(c.id))
  end

  def query({"jobs_comments_replies", JobCommentReply}, %{filter: filter}) do
    JobCommentReply
    |> QueryBuilder.load_inner_replies(filter)
  end

  def query({"jobs_comments_replies", JobCommentReply}, %{reply_to: _}) do
    JobCommentReply
    |> join(:inner, [c], r in assoc(c, :job_comment))
    |> select([c, r], r)
  end

  def query({"jobs_comments_likes", JobCommentLike}, %{count: _}) do
    JobCommentLike
    |> group_by([f], f.job_comment_id)
    |> select([f], count(f.id))
  end

  def query({"jobs_comments_likes", JobCommentLike}, %{viewer_did: _, cur_user: cur_user}) do
    JobCommentLike |> where([f], f.user_id == ^cur_user.id)
  end

  def query({"jobs_comments_likes", JobCommentLike}, %{filter: _filter} = args) do
    JobCommentLike |> QueryBuilder.members_pack(args)
  end

  def query({"jobs_comments_dislikes", JobCommentDislike}, %{count: _}) do
    JobCommentDislike
    |> group_by([f], f.job_comment_id)
    |> select([f], count(f.id))
  end

  def query({"jobs_comments_dislikes", JobCommentDislike}, %{
        viewer_did: _,
        cur_user: cur_user
      }) do
    JobCommentDislike |> where([f], f.user_id == ^cur_user.id)
  end

  def query({"jobs_comments_dislikes", JobCommentDislike}, %{filter: _filter} = args) do
    JobCommentDislike |> QueryBuilder.members_pack(args)
  end

  # ---- job ------

  # ---- video comments ------
  def query({"videos_comments", VideoComment}, %{count: _}) do
    VideoComment
    |> group_by([c], c.video_id)
    |> select([c], count(c.id))
  end

  def query({"videos_comments_replies", VideoCommentReply}, %{count: _}) do
    VideoCommentReply
    |> group_by([c], c.video_comment_id)
    |> select([c], count(c.id))
  end

  def query({"videos_comments_replies", VideoCommentReply}, %{filter: filter}) do
    VideoCommentReply |> QueryBuilder.load_inner_replies(filter)
  end

  def query({"videos_comments_replies", VideoCommentReply}, %{reply_to: _}) do
    VideoCommentReply
    |> join(:inner, [c], r in assoc(c, :video_comment))
    |> select([c, r], r)
  end

  def query({"videos_comments_likes", VideoCommentLike}, %{count: _}) do
    VideoCommentLike
    |> group_by([f], f.video_comment_id)
    |> select([f], count(f.id))
  end

  def query({"videos_comments_likes", VideoCommentLike}, %{viewer_did: _, cur_user: cur_user}) do
    VideoCommentLike |> where([f], f.user_id == ^cur_user.id)
  end

  def query({"videos_comments_likes", VideoCommentLike}, %{filter: _filter} = args) do
    VideoCommentLike
    |> QueryBuilder.members_pack(args)
  end

  def query({"videos_comments_dislikes", VideoCommentDislike}, %{count: _}) do
    VideoCommentDislike
    |> group_by([f], f.video_comment_id)
    |> select([f], count(f.id))
  end

  # component dislikes
  def query({"videos_comments_dislikes", VideoCommentDislike}, %{
        viewer_did: _,
        cur_user: cur_user
      }) do
    VideoCommentDislike |> where([f], f.user_id == ^cur_user.id)
  end

  def query({"videos_comments_dislikes", VideoCommentDislike}, %{filter: _filter} = args) do
    VideoCommentDislike
    |> QueryBuilder.members_pack(args)
  end

  # ---- video ------

  # --- repo comments ------
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
