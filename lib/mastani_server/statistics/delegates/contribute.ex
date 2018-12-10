defmodule MastaniServer.Statistics.Delegate.Contribute do
  import Ecto.Query, warn: false
  import Helper.Utils
  import ShortMaps

  alias MastaniServer.Repo
  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS.Community
  alias MastaniServer.Statistics.{UserContribute, CommunityContribute}
  alias Helper.{ORM, QueryBuilder}

  @community_contribute_days get_config(:general, :community_contribute_days)
  @user_contribute_months get_config(:general, :user_contribute_months)

  def make_contribute(%Community{id: id}) do
    today = Timex.today() |> Date.to_iso8601()

    with {:ok, contribute} <- ORM.find_by(CommunityContribute, community_id: id, date: today) do
      contribute |> inc_contribute_count(:community) |> done
    else
      {:error, _} ->
        CommunityContribute |> ORM.create(%{community_id: id, date: today, count: 1})
    end
  end

  def make_contribute(%User{id: id}) do
    today = Timex.today() |> Date.to_iso8601()

    with {:ok, contribute} <- ORM.find_by(UserContribute, user_id: id, date: today) do
      contribute |> inc_contribute_count(:user) |> done
    else
      {:error, _} ->
        UserContribute |> ORM.create(%{user_id: id, date: today, count: 1})
    end
  end

  @doc """
  Returns the list of user_contribute by latest 6 months.
  """
  def list_contributes(%User{id: id}) do
    user_id = tobe_integer(id)

    "user_contributes"
    |> where([c], c.user_id == ^user_id)
    |> QueryBuilder.recent_inserted(months: @user_contribute_months)
    |> select([c], %{date: c.date, count: c.count})
    |> Repo.all()
    |> to_contributes_map()
    |> done
  end

  def list_contributes(%Community{id: id}) do
    %Community{id: id}
    |> get_contributes()
    |> to_counts_digest(days: @community_contribute_days)
    |> done
  end

  def list_contributes_digest(%Community{id: id}) do
    %Community{id: id}
    |> get_contributes()
    |> to_counts_digest(days: @community_contribute_days)
    |> done
  end

  defp get_contributes(%Community{id: id}) do
    community_id = tobe_integer(id)

    "community_contributes"
    |> where([c], c.community_id == ^community_id)
    |> QueryBuilder.recent_inserted(days: @community_contribute_days)
    |> select([c], %{date: c.date, count: c.count})
    |> Repo.all()
    |> to_contribute_records()
  end

  defp to_contributes_map(data) do
    end_date = Timex.today()
    start_date = Timex.shift(Timex.today(), months: -6)
    total_count = Enum.reduce(data, 0, &(&1.count + &2))

    records = data
    ~m(start_date end_date total_count records)a
  end

  defp to_contribute_records(data) do
    data
    |> Enum.map(fn %{count: count, date: date} ->
      %{
        date: date,
        count: count
      }
    end)
  end

  # 返回 count 数组，方便前端绘图
  # example:
  # from: [0,0,0,0,0,0]
  # to: [0,30,3,8,0,0]
  # 如果 7 天都有 count, 不用计算直接 map 返回
  defp to_counts_digest(record, days: count) do
    case length(record) == @community_contribute_days + 1 do
      true ->
        Enum.map(record, & &1.count)

      false ->
        today = Timex.today() |> Date.to_erl()
        return_count = abs(count) + 1
        enmpty_tuple = return_count |> repeat(0) |> List.to_tuple()

        results =
          Enum.reduce(record, enmpty_tuple, fn record, acc ->
            diff = Timex.diff(Timex.to_date(record.date), today, :days)
            index = diff + abs(count)

            put_elem(acc, index, record.count)
          end)

        results |> Tuple.to_list()
    end
  end

  defp inc_contribute_count(contribute, :community) do
    CommunityContribute
    |> where([c], c.community_id == ^contribute.community_id and c.date == ^contribute.date)
    |> do_inc_count(contribute)
  end

  defp inc_contribute_count(contribute, :user) do
    UserContribute
    |> where([c], c.user_id == ^contribute.user_id and c.date == ^contribute.date)
    |> do_inc_count(contribute)
  end

  defp do_inc_count(query, contribute, count \\ 1) do
    {1, [result]} =
      Repo.update_all(
        from(p in query, select: p.count),
        inc: [count: count]
      )

    put_in(contribute.count, result)
  end
end
