defmodule GroupherServer.Statistics.Delegate.Contribute do
  @moduledoc """
  contribute statistics for user and community, record how many content
  has been add to it
  """
  import Ecto.Query, warn: false
  import Helper.Utils
  import ShortMaps

  alias GroupherServer.{Accounts, CMS, Repo, Statistics}

  alias Accounts.Model.User
  alias CMS.Model.Community
  alias Statistics.Model.{CommunityContribute, UserContribute}

  alias CMS.Delegate.CommunityCURD

  alias Helper.{Cache, Later, ORM, QueryBuilder}
  alias Ecto.Multi

  @community_contribute_days get_config(:general, :community_contribute_days)
  @user_contribute_months get_config(:general, :user_contribute_months)

  @doc """
  update user's contributes record
  """
  def make_contribute(%User{id: id}) do
    today = Timex.today() |> Date.to_iso8601()

    with {:ok, user} <- ORM.find(User, id) do
      Multi.new()
      |> Multi.run(:make_contribute, fn _, _ ->
        case ORM.find_by(UserContribute, user_id: id, date: today) do
          {:ok, contribute} -> update_contribute_record(contribute)
          {:error, _} -> insert_contribute_record(user)
        end
      end)
      |> Multi.run(:update_community_field, fn _, _ ->
        {:ok, contributes} = list_contributes_digest(user)
        ORM.update_embed(user, :contributes, contributes)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  update community's contributes record
  """
  def make_contribute(%Community{id: id}) do
    today = Timex.today() |> Date.to_iso8601()

    Multi.new()
    |> Multi.run(:make_contribute, fn _, _ ->
      case ORM.find_by(CommunityContribute, %{community_id: id, date: today}) do
        {:ok, contribute} -> update_contribute_record(contribute)
        {:error, _} -> insert_contribute_record(%Community{id: id})
      end
    end)
    |> Multi.run(:update_community_field, fn _, _ ->
      contributes_digest =
        %Community{id: id}
        |> do_get_contributes()
        |> to_counts_digest(days: @community_contribute_days)

      CommunityCURD.update_community(id, %{contributes_digest: contributes_digest})
    end)
    |> Repo.transaction()
    |> result()
  end

  @doc """
  Returns the list of user_contribute by latest 6 days.
  """
  def list_contributes_digest(%User{id: id}) do
    user_id = integerfy(id)

    UserContribute
    |> where([c], c.user_id == ^user_id)
    |> QueryBuilder.recent_inserted(months: @user_contribute_months)
    |> select([c], %{date: c.date, count: c.count})
    |> Repo.all()
    |> to_contributes_map()
    |> done
  end

  @doc """
  Returns the list of community_contribute by latest 6 days.
  """
  def list_contributes_digest(%Community{id: id}) do
    scope = Cache.get_scope(:community_contributes, id)

    case Cache.get(:common, scope) do
      {:ok, result} -> {:ok, result}
      {:error, _} -> get_contributes_then_cache(%Community{id: id})
    end
  end

  # NOTE*  must be public, cause it will be exec by background job
  def get_contributes_then_cache(%Community{id: id}) do
    scope = Cache.get_scope(:community_contributes, id)

    %Community{id: id}
    |> do_get_contributes()
    |> to_counts_digest(days: @community_contribute_days)
    |> done_and_cache(:common, scope, expire_min: 10)
  end

  defp update_contribute_record(%UserContribute{} = contribute) do
    contribute |> inc_contribute_count(:user) |> done
  end

  defp update_contribute_record(%CommunityContribute{community_id: community_id} = contribute) do
    with {:ok, result} <- inc_contribute_count(contribute, :community) |> done do
      cache_contribute_later(%Community{id: community_id})
      {:ok, result}
    end
  end

  defp insert_contribute_record(%User{id: id}) do
    today = Timex.today() |> Date.to_iso8601()

    UserContribute |> ORM.create(%{user_id: id, date: today, count: 1})
  end

  defp insert_contribute_record(%Community{id: id}) do
    today = Timex.today() |> Date.to_iso8601()

    with {:ok, result} <-
           ORM.create(CommunityContribute, %{community_id: id, date: today, count: 1}) do
      cache_contribute_later(%Community{id: id})
      {:ok, result}
    end
  end

  defp cache_contribute_later(%Community{id: id}) do
    Later.run({__MODULE__, :get_contributes_then_cache, [%Community{id: id}]})
  end

  defp do_get_contributes(%Community{id: id}) do
    community_id = integerfy(id)

    CommunityContribute
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
    |> Enum.map(fn %{count: count, date: date} -> %{date: date, count: count} end)
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

        Enum.reduce(record, enmpty_tuple, fn record, acc ->
          diff = Timex.diff(Timex.to_date(record.date), today, :days)
          index = diff + abs(count)

          put_elem(acc, index, record.count)
        end)
        |> Tuple.to_list()
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

  defp result({:ok, %{make_contribute: result}}), do: {:ok, result}
  defp result({:error, _, result, _steps}), do: {:error, result}
end
