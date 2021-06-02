defmodule Helper.QueryBuilder do
  # alias GroupherServer.Repo
  import Ecto.Query, warn: false

  @doc """
  handle [3] situation:

  1. basic query with filter
  2. reaction_user's count
  3. is viewer reacted?

  bewteen [THREAD] and [REACT]
  [REACT]; upvotes, stars, watchs ...
  """
  def members_pack(queryable, %{filter: filter}) do
    queryable |> load_inner_users(filter)
  end

  # def members_pack(queryable, %{count: _, type: :community}) do
  #   queryable
  #   |> group_by([f], f.community_id)
  #   |> select([f], count(f.id))
  # end

  def load_inner_users(queryable, filter) do
    queryable
    |> join(:inner, [f], u in assoc(f, :user))
    |> select([f, u], u)
    |> filter_pack(filter)
  end

  @doc """
  inserted in latest x mounth
  """
  def recent_inserted(queryable, months: count) do
    end_of_today = Timex.now() |> Timex.end_of_day()
    x_months_ago = Timex.today() |> Timex.shift(months: -count) |> Timex.to_datetime()

    queryable
    |> where([q], q.inserted_at >= ^x_months_ago)
    |> where([q], q.inserted_at <= ^end_of_today)
  end

  @doc """
  inserted in latest x days
  """
  def recent_inserted(queryable, days: count) do
    end_of_today = Timex.now() |> Timex.end_of_day()
    x_days_ago = Timex.today() |> Timex.shift(days: -count) |> Timex.to_datetime()

    queryable
    |> where([q], q.inserted_at >= ^x_days_ago)
    |> where([q], q.inserted_at <= ^end_of_today)
  end

  # this is strategy will cause
  # defp sort_strategy(:desc_inserted), do: [desc: :inserted_at, desc: :views]
  # defp sort_strategy(:most_views), do: [desc: :views, desc: :inserted_at]
  # defp sort_strategy(:least_views), do: [asc: :views, desc: :inserted_at]
  # defp strategy(:most_stars), do: [desc: :views, desc: :inserted_at]

  defp sort_by_count(queryable, field, direction) do
    queryable
    |> join(:left, [p], s in assoc(p, ^field))
    |> group_by([p], p.id)
    |> select([p], p)
    |> order_by([_, s], {^direction, fragment("count(?)", s.id)})
  end

  def filter_pack(queryable, filter) when is_map(filter) do
    Enum.reduce(filter, queryable, fn
      {:sort, :desc_active}, queryable ->
        queryable |> order_by(desc: :active_at)

      {:sort, :desc_inserted}, queryable ->
        # queryable |> order_by(^sort_strategy(:desc_inserted))
        queryable |> order_by(desc: :inserted_at)

      {:sort, :desc_active}, queryable ->
        queryable |> order_by(desc: :active_at)

      {:sort, :asc_inserted}, queryable ->
        queryable |> order_by(asc: :inserted_at)

      {:sort, :desc_index}, queryable ->
        queryable |> order_by(desc: :index)

      {:sort, :asc_index}, queryable ->
        queryable |> order_by(asc: :index)

      {:sort, :most_views}, queryable ->
        # this will cause error in Dialyzer
        # queryable |> order_by(^sort_strategy(:most_views))
        queryable |> order_by(desc: :views, desc: :inserted_at)

      {:sort, :least_views}, queryable ->
        # queryable |> order_by(^sort_strategy(:least_views))
        queryable |> order_by(asc: :views, desc: :inserted_at)

      {:sort, :most_stars}, queryable ->
        queryable |> sort_by_count(:stars, :desc)

      {:sort, :least_stars}, queryable ->
        queryable |> sort_by_count(:stars, :asc)

      {:sort, :most_likes}, queryable ->
        queryable |> sort_by_count(:likes, :desc)

      {:length, :most_words}, queryable ->
        queryable |> order_by(desc: :length)

      {:length, :least_words}, queryable ->
        queryable |> order_by(asc: :length)

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

      {:article_tag, tag_name}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :article_tags),
          where: t.title == ^tag_name
        )

      {:article_tags, tag_name_list}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :article_tags),
          where: t.title in ^tag_name_list,
          distinct: q.id,
          group_by: q.id
        )

      {:category, catetory_raw}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :categories),
          where: t.raw == ^catetory_raw
        )

      {:thread, thread}, queryable ->
        thread = thread |> to_string |> String.upcase()
        from(q in queryable, where: q.thread == ^thread)

      {:community_id, community_id}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :community),
          where: t.id == ^community_id
        )

      {:community, community_raw}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :communities),
          where: t.raw == ^community_raw
        )

      {:one_community, community_raw}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :community),
          where: t.raw == ^community_raw
        )

      {:first, first}, queryable ->
        queryable |> limit(^first)

      # {:pin, bool}, queryable ->
      #   queryable
      #   |> where([p], p.pin == ^bool)

      {:mark_delete, bool}, queryable ->
        queryable |> where([p], p.mark_delete == ^bool)

      {_, _}, queryable ->
        queryable
    end)
  end
end
