defmodule Helper.QueryBuilder do
  # alias MastaniServer.Repo
  import Ecto.Query, warn: false

  @doc """
  handle [3] situation:

  1. basic query with filter
  2. reaction_user's count
  3. is viewer reacted?

  bewteen [PART] and [REACT]
  [PART]: cms part, include: Post, Job, Meetup ...
  [REACT]; favorites, stars, watchs ...
  """
  def reactions_hanlder(queryable, %{filter: filter}) do
    queryable |> reaction_members(filter)
  end

  def reactions_hanlder(queryable, %{arg_count: _}) do
    # TODO post_id should be general
    queryable
    |> group_by([f], f.post_id)
    |> select([f], count(f.id))
  end

  def reactions_hanlder(queryable, %{arg_viewer_reacted: _, current_user: current_user}) do
    queryable |> where([f], f.user_id == ^current_user.id)
  end

  def reaction_members(queryable, filter) do
    queryable
    |> join(:inner, [f], u in assoc(f, :user))
    |> select([f, u], u)
    |> filter_pack(filter)
  end

  defp sort_strategy(:most_views), do: [desc: :views, desc: :inserted_at]
  defp sort_strategy(:least_views), do: [asc: :views, desc: :inserted_at]
  # this is strategy will cause
  defp sort_strategy(:desc_inserted), do: [desc: :inserted_at, desc: :views]
  # defp strategy(:most_stars), do: [desc: :views, desc: :inserted_at]

  def filter_pack(queryable, filter) do
    Enum.reduce(filter, queryable, fn
      {:sort, :desc_inserted}, queryable ->
        # queryable |> order_by(^sort_strategy(:desc_inserted))
        queryable |> order_by(desc: :inserted_at)

      {:sort, :most_views}, queryable ->
        queryable |> order_by(^sort_strategy(:most_views))

      {:sort, :least_views}, queryable ->
        queryable |> order_by(^sort_strategy(:least_views))

      {:sort, :most_stars}, queryable ->
        queryable
        |> join(:left, [p], s in assoc(p, :stars))
        |> group_by([p], p.id)
        |> select([p], p)
        |> order_by([p, s], desc: fragment("count(?)", s.id))

      {:sort, :least_stars}, queryable ->
        queryable
        |> join(:left, [p], s in assoc(p, :stars))
        |> group_by([p], p.id)
        |> select([p], p)
        |> order_by([p, s], asc: fragment("count(?)", s.id))

      {:when, :today}, queryable ->
        # date = DateTime.utc_now() |> Timex.to_datetime()
        # use timezone info is server is not in the some timezone
        # Timex.now("America/Chicago")
        date = Timex.now()

        queryable
        |> where([p], p.inserted_at >= ^Timex.beginning_of_day(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_day(date))

      {:when, :this_week}, queryable ->
        date = Timex.now()

        queryable
        |> where([p], p.inserted_at >= ^Timex.beginning_of_week(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_week(date))

      {:when, :this_month}, queryable ->
        date = Timex.now()

        queryable
        |> where([p], p.inserted_at >= ^Timex.beginning_of_month(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_month(date))

      {:when, :this_year}, queryable ->
        date = Timex.now()

        queryable
        |> where([p], p.inserted_at >= ^Timex.beginning_of_year(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_year(date))

      # TODO :all
      {_, :all}, queryable ->
        queryable

      {:tag, tag_name}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :tags),
          where: t.title == ^tag_name
        )

      {:community, community_name}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :communities),
          where: t.title == ^community_name
        )

      {:first, first}, queryable ->
        queryable |> limit(^first)

      {_, _}, queryable ->
        queryable
    end)
  end
end
