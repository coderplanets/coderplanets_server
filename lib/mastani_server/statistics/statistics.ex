defmodule MastaniServer.Statistics do
  @moduledoc """
  The Statistics context.
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, tobe_integer: 1]

  alias MastaniServer.Repo
  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS.Community
  alias MastaniServer.Statistics.{UserContributes, CommunityContributes}
  alias Helper.{ORM, QueryBuilder}

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
    |> QueryBuilder.recent_inserted(mounths: 6)
    |> select([c], %{date: c.date, count: c.count})
    |> Repo.all()
    |> to_contribute_map
    |> done
  end

  def list_contributes(%Community{id: id}) do
    community_id = tobe_integer(id)

    "community_contributes"
    |> where([c], c.community_id == ^community_id)
    |> QueryBuilder.recent_inserted(days: 7)
    |> select([c], %{date: c.date, count: c.count})
    |> Repo.all()
    |> to_contribute_map
    |> done
  end

  defp to_contribute_map(data) do
    data
    |> Enum.map(fn %{count: count, date: date} -> %{date: convert_date(date), count: count} end)
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
