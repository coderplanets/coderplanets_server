defmodule MastaniServer.Statistics do
  @moduledoc """
  The Statistics context.
  """

  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]

  alias MastaniServer.Repo
  alias MastaniServer.Accounts.User
  alias MastaniServer.Statistics.UserContributes
  alias Helper.ORM

  @doc """
  Returns the list of user_contributes.
  """
  def make_contribute(%User{} = user) do
    today = Timex.today() |> Date.to_iso8601()

    user_id =
      if is_integer(user.id),
        do: user.id,
        else: user.id |> String.to_integer()

    with {:ok, contribute} <- ORM.find_by(UserContributes, user_id: user_id, date: today) do
      inc_contribute_count(contribute) |> done
    else
      {:error, _} ->
        %UserContributes{}
        |> UserContributes.changeset(%{user_id: user_id, date: today, count: 1})
        |> Repo.insert()
    end
  end

  def list_user_contributes(%User{} = user) do
    end_of_today = Timex.now() |> Timex.end_of_day()
    six_month_ago = Timex.shift(Timex.today(), months: -6) |> Timex.to_datetime()

    user_id =
      if is_integer(user.id),
        do: user.id,
        else: user.id |> String.to_integer()

    query =
      from(
        c in "user_contributes",
        where: c.user_id == ^user_id,
        where: c.inserted_at >= ^six_month_ago,
        where: c.inserted_at <= ^end_of_today,
        # where: c.date >= ^(Timex.shift(today, months: -6) |> Date.to_iso8601),
        # where: c.date <= ^(Timex.end_of_day(today) |> Date.to_iso8601),
        select: %{date: c.date, count: c.count}
      )

    Repo.all(query) |> to_contribute_map |> done
  end

  defp to_contribute_map(data) do
    data
    |> Enum.map(fn %{count: count, date: date} -> %{date: convert_date(date), count: count} end)
  end

  defp convert_date(date) do
    {:ok, edate} = Date.from_erl(date)
    edate
  end

  defp inc_contribute_count(contribute) do
    {1, [result]} =
      Repo.update_all(
        from(
          c in UserContributes,
          where: c.user_id == ^contribute.user_id and c.date == ^contribute.date
        ),
        [inc: [count: 1]],
        returning: [:count]
      )

    put_in(contribute.count, result.count)
  end
end
