defmodule MastaniServer.Test.Query.Accounts.FavritedPosts do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, user} = db_insert(:user)

    total_count = 20
    {:ok, posts} = db_insert_multi(:post, total_count)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn user total_count posts)a}
  end

  describe "[account favorited posts]" do
    @query """
    query($filter: PagedFilter!) {
      account {
        id
        favoritedPosts(filter: $filter) {
          entries {
            id
          }
          totalCount
        }
        favoritedPostsCount
      }
    }
    """
    test "login user can get it's own favoritedPosts", ~m(user_conn user total_count posts)a do
      Enum.each(posts, fn post ->
        {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
      end)

      random_id = posts |> Enum.shuffle() |> List.first() |> Map.get(:id) |> to_string

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "account")
      assert results["favoritedPosts"] |> Map.get("totalCount") == total_count
      assert results["favoritedPostsCount"] == total_count

      assert results["favoritedPosts"]
             |> Map.get("entries")
             |> Enum.any?(&(&1["id"] == random_id))
    end

    @query """
    query($userId: ID, $filter: PagedFilter!) {
      favoritedPosts(userId: $userId, filter: $filter) {
        entries {
          id
        }
        totalCount
      }
    }
    """
    test "other user can get other user's paged favoritedPosts",
         ~m(user_conn guest_conn total_count posts)a do
      {:ok, user} = db_insert(:user)

      Enum.each(posts, fn post ->
        {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
      end)

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoritedPosts")
      results2 = guest_conn |> query_result(@query, variables, "favoritedPosts")

      assert results["totalCount"] == total_count
      assert results2["totalCount"] == total_count
    end

    test "login user can get self paged favoritedPosts", ~m(user_conn user posts total_count)a do
      Enum.each(posts, fn post ->
        {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
      end)

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoritedPosts")

      assert results["totalCount"] == total_count
    end
  end
end
