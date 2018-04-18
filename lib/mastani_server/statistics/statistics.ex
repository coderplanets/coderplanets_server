defmodule MastaniServer.Statistics do
  @moduledoc """
  The Statistics context.
  """
  import Ecto.Query, warn: false
  import Helper.Utils

  alias MastaniServer.Repo
  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS.Community
  alias MastaniServer.Statistics.{UserContributes, CommunityContributes}
  alias Helper.{ORM, QueryBuilder}

  @community_contribute_days get_config(:general, :community_contribute_days)
  @user_contribute_months get_config(:general, :user_contribute_months)

  def make_contribute(%Community{id: id}) do
    today = Timex.today() |> Date.to_iso8601()

    with {:ok, contribute} <- ORM.find_by(CommunityContributes, community_id: id, date: today) do
      inc_contribute_count(contribute, :community) |> done
    else
      {:error, _} ->
        %CommunityContributes{}
        |> CommunityContributes.changeset(%{community_id: id, date: today, count: 1})
        |> Repo.insert()
    end
  end

  def make_contribute(%User{id: id}) do
    today = Timex.today() |> Date.to_iso8601()

    with {:ok, contribute} <- ORM.find_by(UserContributes, user_id: id, date: today) do
      inc_contribute_count(contribute, :user) |> done
    else
      {:error, _} ->
        %UserContributes{}
        |> UserContributes.changeset(%{user_id: id, date: today, count: 1})
        |> Repo.insert()
    end
  end

  @doc """
  Returns the list of user_contributes by latest 6 months.
  """
  def list_contributes(%User{id: id}) do
    user_id = tobe_integer(id)

    "user_contributes"
    |> where([c], c.user_id == ^user_id)
    |> QueryBuilder.recent_inserted(mounths: @user_contribute_months)
    |> select([c], %{date: c.date, count: c.count})
    |> Repo.all()
    |> to_contribute_map()
    |> done
  end

  def list_contributes(%Community{id: id}) do
    %Community{id: id}
    |> get_contributes()
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
    |> to_contribute_map()
  end

  defp to_contribute_map(data) do
    data
    |> Enum.map(fn %{count: count, date: date} ->
      %{
        date: convert_date(date),
        count: count
      }
    end)
  end

  defp to_counts_digest(data, days: count) do
    # 如果 7 天都有 count, 不用计算直接 map 返回
    case length(data) == @community_contribute_days + 1 do
      true ->
        Enum.map(data, & &1.count)

      false ->
        today = Timex.today() |> Date.to_erl()
        result = repeat(abs(count) + 1, 0) |> List.to_tuple()

        Enum.reduce(data, result, fn record, acc ->
          diff = Timex.diff(Timex.to_date(record.date), today, :days)
          index = diff + abs(count)

          put_elem(acc, index, record.count)
        end)
        |> Tuple.to_list()
    end
  end

  defp convert_date(date) do
    {:ok, edate} = Date.from_erl(date)
    edate
  end

  defp inc_contribute_count(contribute, :community) do
    CommunityContributes
    |> where([c], c.community_id == ^contribute.community_id and c.date == ^contribute.date)
    |> do_inc_count(contribute)
  end

  defp inc_contribute_count(contribute, :user) do
    UserContributes
    |> where([c], c.user_id == ^contribute.user_id and c.date == ^contribute.date)
    |> do_inc_count(contribute)
  end

  defp do_inc_count(query, contribute, count \\ 1) do
    {1, [result]} =
      Repo.update_all(
        query,
        [inc: [count: count]],
        returning: [:count]
      )

    put_in(contribute.count, result.count)
  end
end
