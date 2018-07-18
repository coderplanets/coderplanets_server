defmodule MastaniServer.Test.Query.Account.AchieveMentTest do
  use MastaniServer.TestTools
  import Helper.Utils, only: [get_config: 2]
  alias MastaniServer.Accounts

  @follow_weight get_config(:general, :user_achieve_follow_weight)
  @favorite_weight get_config(:general, :user_achieve_favorite_weight)
  @star_weight get_config(:general, :user_achieve_star_weight)

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[account followe achieveMent]" do
    @query """
    query($id: ID!) {
      user(id: $id) {
        id
        achievement {
          reputation
          followersCount
        }
      }
    }
    """
    @tag :wip
    test "new you has no acheiveements", ~m(guest_conn user)a do
      variables = %{id: user.id}
      results = guest_conn |> query_result(@query, variables, "user")

      assert is_nil(results["achievement"])
    end

    @tag :wip
    test "can query other user's achievement after user has one", ~m(guest_conn user)a do
      {:ok, user2} = db_insert(:user)
      user2 |> Accounts.follow(user)

      variables = %{id: user.id}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results["achievement"] |> Map.get("followersCount") == @follow_weight
      assert results["achievement"] |> Map.get("reputation") == @follow_weight
    end
  end
end
