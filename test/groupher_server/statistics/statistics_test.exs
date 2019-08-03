defmodule GroupherServer.Test.Statistics do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.{Cache, Later, ORM}
  alias GroupherServer.Accounts.User
  alias GroupherServer.{CMS, Repo, Statistics}

  @community_contribute_days get_config(:general, :community_contribute_days)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, ~m(user community)a}
  end

  describe "[statistics user_contribute] " do
    alias Statistics.UserContribute

    test "list_contributes return empty list when theres no records", ~m(user)a do
      {:ok, contributes} = Statistics.list_contributes_digest(%User{id: user.id})
      assert contributes.records == []
      assert contributes.total_count == 0
    end

    test "list_contributes return proper format ", ~m(user)a do
      Statistics.make_contribute(%User{id: user.id})
      {:ok, contributes} = Statistics.list_contributes_digest(%User{id: user.id})
      # contributes[0]
      assert contributes |> Map.has_key?(:start_date)
      assert contributes |> Map.has_key?(:end_date)
      assert contributes |> Map.has_key?(:total_count)
      assert [:count, :date] == contributes.records |> List.first() |> Map.keys()
    end

    test "should return recent 6 month contributes of a user by default", ~m(user)a do
      six_month_ago = Timex.shift(Timex.today(), months: -6)
      six_more_month_ago = Timex.shift(six_month_ago, days: -10)

      Repo.insert_all(UserContribute, [
        %{
          user_id: user.id,
          date: six_month_ago,
          count: 1,
          inserted_at: six_month_ago |> Timex.to_datetime(),
          updated_at: six_month_ago |> Timex.to_datetime()
        },
        %{
          user_id: user.id,
          date: six_more_month_ago,
          count: 1,
          inserted_at: six_more_month_ago |> Timex.to_datetime(),
          updated_at: six_more_month_ago |> Timex.to_datetime()
        }
      ])

      {:ok, contributes} = Statistics.list_contributes_digest(%User{id: user.id})
      assert length(contributes.records) == 1
    end

    test "should inserted a contribute when the user not contribute before", ~m(user)a do
      assert {:error, _} = ORM.find_by(UserContribute, user_id: user.id)

      Statistics.make_contribute(%User{id: user.id})
      assert {:ok, contribute} = ORM.find_by(UserContribute, user_id: user.id)

      assert contribute.user_id == user.id
      assert contribute.count == 1
      assert contribute.date == Timex.today()
    end

    test "should update a contribute when the user has contribute before", ~m(user)a do
      Statistics.make_contribute(%User{id: user.id})
      assert {:ok, first} = ORM.find_by(UserContribute, user_id: user.id)

      assert first.user_id == user.id
      assert first.count == 1

      Statistics.make_contribute(%User{id: user.id})
      assert {:ok, second} = ORM.find_by(UserContribute, user_id: user.id)

      assert second.user_id == user.id
      assert second.count == 2
    end
  end

  describe "[statistics community_contribute] " do
    alias CMS.Community
    alias Statistics.CommunityContribute

    test "should inserted a community contribute when create community", ~m(community)a do
      community_id = community.id
      assert {:error, _} = ORM.find_by(CommunityContribute, ~m(community_id)a)

      Statistics.make_contribute(%Community{id: community.id})

      assert {:ok, contribute} = ORM.find_by(CommunityContribute, ~m(community_id)a)

      assert contribute.community_id == community.id
      assert contribute.count == 1
      assert contribute.date == Timex.today()
    end

    test "should update a contribute when make communityContribute before", ~m(community)a do
      community_id = community.id

      Statistics.make_contribute(%Community{id: community.id})

      assert {:ok, first} = ORM.find_by(CommunityContribute, ~m(community_id)a)

      assert first.community_id == community.id
      assert first.count == 1

      Statistics.make_contribute(%Community{id: community.id})

      assert {:ok, second} = ORM.find_by(CommunityContribute, ~m(community_id)a)

      assert second.community_id == community.id
      assert second.count == 2
    end

    test "should return recent #{@community_contribute_days} days community contributes by default",
         ~m(community)a do
      days_ago = Timex.shift(Timex.today(), days: -@community_contribute_days)
      more_days_ago = Timex.shift(days_ago, days: -1)

      Repo.insert_all(CommunityContribute, [
        %{
          community_id: community.id,
          date: days_ago,
          count: 1,
          inserted_at: days_ago |> Timex.to_datetime(),
          updated_at: days_ago |> Timex.to_datetime()
        },
        %{
          community_id: community.id,
          date: more_days_ago,
          count: 1,
          inserted_at: more_days_ago |> Timex.to_datetime(),
          updated_at: more_days_ago |> Timex.to_datetime()
        }
      ])

      {:ok, contributes} = Statistics.list_contributes_digest(%Community{id: community.id})
      assert length(contributes) == @community_contribute_days + 1
    end

    test "the contributes data should be cached after first query", ~m(community)a do
      scope = Cache.get_scope(:community_contributes, community.id)
      assert {:error, nil} = Cache.get(scope)

      {:ok, contributes} = Statistics.list_contributes_digest(%Community{id: community.id})

      assert {:ok, contributes} = Cache.get(scope)
    end

    test "Rihanna should work in test sandbox", ~m(community)a do
      res = Rihanna.enqueue({IO, :puts, ["Work, work, work, work, work."]})
      Process.sleep(1000)
      # IO.inspect(res, label: "res")
    end

    test "cache should be update after make contributes", ~m(community)a do
      scope = Cache.get_scope(:community_contributes, community.id)
      assert {:error, nil} = Cache.get(scope)

      Statistics.make_contribute(%Community{id: community.id})

      # res = Later.exec({IO, :puts, ["Work, work, work, work, work."]})
      # Process.sleep(1000)
      # IO.inspect(res, label: "res")

      # assert {:ok, _} = Cache.get(scope)
    end
  end
end
