defmodule MastaniServer.Test.StatisticsTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  alias MastaniServer.Statistics
  alias MastaniServer.Accounts.User
  alias Helper.ORM
  alias MastaniServer.Repo

  @valid_user mock_attrs(:user)
  @valid_user2 mock_attrs(:user)

  # @valid_attrs %{count: 42, date: ~D[2010-04-17]}
  # @update_attrs %{count: 43, date: ~D[2011-05-18]}
  # @invalid_attrs %{count: nil, date: nil}
  setup do
    {:ok, user} = db_insert(:user, @valid_user)
    {:ok, user2} = db_insert(:user, @valid_user2)
    {:ok, user: user, user2: user2}
  end

  describe "[statistics user_contributes] " do
    test "list_user_contributes return empty list when theres no records", %{user: user} do
      assert {:ok, []} == Statistics.list_user_contributes(%User{id: user.id})
    end

    test "list_user_contributes return proper format ", %{user: user} do
      Statistics.make_contribute(%User{id: user.id})
      {:ok, contributes} = Statistics.list_user_contributes(%User{id: user.id})
      # contributes[0]
      assert [:count, :date] == contributes |> List.first() |> Map.keys()
    end

    test "list_user_contributes should last 6 month contributes of a user by default", %{
      user: user
    } do
      six_month_ago = Timex.shift(Timex.today(), months: -6)
      six_more_month_ago = Timex.shift(six_month_ago, days: -10)

      Repo.insert_all(Statistics.UserContributes, [
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

      {:ok, contributes} = Statistics.list_user_contributes(%User{id: user.id})

      # assert contributes |> List.first |> Map.get(:date) |> Date.to_iso8601 == six_month_ago |> Date.to_iso8601
      # IO.inspect(contributes, label: "contributes")
      assert length(contributes) == 1
      true
    end

    test "should inserted a contribute when the user not contribute before", %{user: user} do
      assert {:error, _} = ORM.find_by(Statistics.UserContributes, user_id: user.id)

      Statistics.make_contribute(%User{id: user.id})
      assert {:ok, contribute} = ORM.find_by(Statistics.UserContributes, user_id: user.id)

      assert contribute.user_id == user.id
      assert contribute.count == 1
      assert contribute.date == Timex.today()
    end

    test "should update a contribute when the user has contribute before", %{user: user} do
      Statistics.make_contribute(%User{id: user.id})
      assert {:ok, first} = ORM.find_by(Statistics.UserContributes, user_id: user.id)

      assert first.user_id == user.id
      assert first.count == 1

      Statistics.make_contribute(%User{id: user.id})
      assert {:ok, second} = ORM.find_by(Statistics.UserContributes, user_id: user.id)

      assert second.user_id == user.id
      assert second.count == 2
    end
  end
end
