defmodule MastaniServer.Test.Query.Account.AchieveMentTest do
  use MastaniServer.TestTools
  import Helper.Utils, only: [get_config: 2]
  alias MastaniServer.Accounts
  alias Helper.ORM

  @follow_weight get_config(:general, :user_achieve_follow_weight)
  @favorite_weight get_config(:general, :user_achieve_favorite_weight)
  # @star_weight get_config(:general, :user_achieve_star_weight)

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[account follow achieveMent]" do
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
    test "new you has no acheiveements", ~m(guest_conn user)a do
      variables = %{id: user.id}
      results = guest_conn |> query_result(@query, variables, "user")

      assert is_nil(results["achievement"])
    end

    test "inc user's achievement after user got followed", ~m(guest_conn user)a do
      {:ok, user2} = db_insert(:user)
      user2 |> Accounts.follow(user)

      variables = %{id: user.id}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results["achievement"] |> Map.get("followersCount") == @follow_weight
      assert results["achievement"] |> Map.get("reputation") == @follow_weight
    end

    test "minus user's achievement after user get cancle followed", ~m(guest_conn user)a do
      total_count = 10
      {:ok, users} = db_insert_multi(:user, total_count)

      Enum.each(users, fn fan ->
        {:ok, _} = fan |> Accounts.follow(user)
      end)

      ramdom_fan = users |> Enum.shuffle() |> List.first()
      ramdom_fan |> Accounts.undo_follow(user)

      variables = %{id: user.id}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results["achievement"] |> Map.get("followersCount") ==
               @follow_weight * (total_count - 1)

      assert results["achievement"] |> Map.get("reputation") == @follow_weight * (total_count - 1)
    end
  end

  describe "[account favorite achieveMent]" do
    alias MastaniServer.CMS

    @query """
    query($id: ID!) {
      user(id: $id) {
        id
        achievement {
          reputation
          contentsFavoritedCount
        }
      }
    }
    """
    test "inc user's achievement after user's post got favorited", ~m(guest_conn user)a do
      {:ok, post} = db_insert(:post)
      {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)

      {:ok, post} = CMS.Post |> ORM.find(post.id, preload: [author: :user])
      author_user_id = post.author.user_id

      variables = %{id: author_user_id}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results["achievement"] |> Map.get("contentsFavoritedCount") == @favorite_weight
      assert results["achievement"] |> Map.get("reputation") == @favorite_weight
    end

    test "minus user's acheiveements after user's post get cancle favorited", ~m(guest_conn)a do
      total_count = 10
      {:ok, post} = db_insert(:post)
      {:ok, users} = db_insert_multi(:user, total_count)

      Enum.each(users, fn user ->
        {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
      end)

      {:ok, post} = CMS.Post |> ORM.find(post.id, preload: [author: :user])
      author_user_id = post.author.user_id

      user = users |> Enum.shuffle() |> List.first()
      {:ok, _} = CMS.undo_reaction(:post, :favorite, post.id, user)

      variables = %{id: author_user_id}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results["achievement"] |> Map.get("contentsFavoritedCount") ==
               @favorite_weight * (total_count - 1)

      assert results["achievement"] |> Map.get("reputation") ==
               @favorite_weight * (total_count - 1)
    end
  end
end
