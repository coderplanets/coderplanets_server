defmodule MastaniServer.Test.Query.Account.Achievement do
  use MastaniServer.TestTools
  import Helper.Utils, only: [get_config: 2]
  alias MastaniServer.{Accounts, CMS}

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

  describe "[account editable-communities]" do
    @query """
    query($userId: ID, $filter: PagedFilter!) {
      editableCommunities(userId: $userId, filter: $filter) {
        entries {
          id
          logo
          title
          raw
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "can get user's empty editable communities list", ~m(guest_conn user)a do
      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "editableCommunities")

      assert results |> is_valid_pagination?(:empty)
    end

    test "can get user's editable communities list when user is editor", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      title = "chief editor"
      {:ok, _} = CMS.set_editor(community, title, user)
      {:ok, _} = CMS.set_editor(community2, title, user)

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "editableCommunities")

      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(community.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(community2.id)))
    end

    @query """
    query {
      account {
        id
        editableCommunities {
          entries {
            id
            logo
            title
            raw
          }
          totalCount
        }
      }
    }
    """
    test "user can get own editable communities list", ~m(user)a do
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      title = "chief editor"
      {:ok, _} = CMS.set_editor(community, title, user)
      {:ok, _} = CMS.set_editor(community2, title, user)

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "account")
      editable_communities = results["editableCommunities"]

      assert editable_communities["totalCount"] == 2
      assert editable_communities["entries"] |> Enum.any?(&(&1["id"] == to_string(community.id)))
      assert editable_communities["entries"] |> Enum.any?(&(&1["id"] == to_string(community2.id)))
    end
  end

  describe "[account follow achieveMent]" do
    @query """
    query($id: ID!) {
      user(id: $id) {
        id
        followersCount
        followingsCount
        achievement {
          reputation
        }
      }
    }
    """
    test "inc user's achievement after user got followed", ~m(guest_conn user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, user3} = db_insert(:user)
      {:ok, user4} = db_insert(:user)

      user2 |> Accounts.follow(user)
      user |> Accounts.follow(user2)
      user3 |> Accounts.follow(user2)
      user3 |> Accounts.follow(user4)

      variables = %{id: user2.id}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results |> Map.get("followersCount") == 2
      assert results["achievement"] |> Map.get("reputation") == 2 * @follow_weight
    end

    test "minus user's achievement after user get undo followed", ~m(guest_conn user)a do
      total_count = 10
      {:ok, users} = db_insert_multi(:user, total_count)

      Enum.each(users, fn fan ->
        {:ok, _} = fan |> Accounts.follow(user)
      end)

      ramdom_fan = users |> Enum.shuffle() |> List.first()
      ramdom_fan |> Accounts.undo_follow(user)

      variables = %{id: user.id}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results |> Map.get("followersCount") == total_count - 1

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

      assert results["achievement"] |> Map.get("contentsFavoritedCount") == 1
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

      assert results["achievement"] |> Map.get("contentsFavoritedCount") == total_count - 1

      assert results["achievement"] |> Map.get("reputation") ==
               @favorite_weight * total_count - @favorite_weight
    end
  end
end
