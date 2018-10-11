defmodule MastaniServer.Test.Query.Accounts.FavritedVideos do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, user} = db_insert(:user)

    total_count = 20
    {:ok, videos} = db_insert_multi(:video, total_count)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn user total_count videos)a}
  end

  describe "[account favorited videos]" do
    @query """
    query($filter: PagedFilter!) {
      account {
        id
        favoritedVideos(filter: $filter) {
          entries {
            id
          }
          totalCount
        }
        favoritedVideosCount
      }
    }
    """
    test "login user can get it's own favoritedVideos", ~m(user_conn user total_count videos)a do
      Enum.each(videos, fn video ->
        {:ok, _} = CMS.reaction(:video, :favorite, video.id, user)
      end)

      random_id = videos |> Enum.shuffle() |> List.first() |> Map.get(:id) |> to_string

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "account")
      assert results["favoritedVideos"] |> Map.get("totalCount") == total_count
      assert results["favoritedVideosCount"] == total_count

      assert results["favoritedVideos"]
             |> Map.get("entries")
             |> Enum.any?(&(&1["id"] == random_id))
    end

    @query """
    query($userId: ID, $categoryId: ID, $filter: PagedFilter!) {
      favoritedVideos(userId: $userId, categoryId: $categoryId, filter: $filter) {
        entries {
          id
        }
        totalCount
      }
    }
    """
    test "other user can get other user's paged favoritedVideos",
         ~m(user_conn guest_conn total_count videos)a do
      {:ok, user} = db_insert(:user)

      Enum.each(videos, fn video ->
        {:ok, _} = CMS.reaction(:video, :favorite, video.id, user)
      end)

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoritedVideos")
      results2 = guest_conn |> query_result(@query, variables, "favoritedVideos")

      assert results["totalCount"] == total_count
      assert results2["totalCount"] == total_count
    end

    test "login user can get self paged favoritedVideos",
         ~m(user_conn user videos total_count)a do
      Enum.each(videos, fn video ->
        {:ok, _} = CMS.reaction(:video, :favorite, video.id, user)
      end)

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoritedVideos")

      assert results["totalCount"] == total_count
    end

    alias MastaniServer.Accounts

    test "can get paged favoritedVideos on a spec category", ~m(user_conn guest_conn videos)a do
      {:ok, user} = db_insert(:user)

      Enum.each(videos, fn video ->
        {:ok, _} = CMS.reaction(:video, :favorite, video.id, user)
      end)

      video1 = Enum.at(videos, 0)
      video2 = Enum.at(videos, 1)
      video3 = Enum.at(videos, 2)
      video4 = Enum.at(videos, 4)

      test_category = "test category"
      test_category2 = "test category2"

      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, category2} = Accounts.create_favorite_category(user, %{title: test_category2})

      {:ok, _favorites_category} = Accounts.set_favorites(user, :video, video1.id, category.id)
      {:ok, _favorites_category} = Accounts.set_favorites(user, :video, video2.id, category.id)
      {:ok, _favorites_category} = Accounts.set_favorites(user, :video, video3.id, category.id)
      {:ok, _favorites_category} = Accounts.set_favorites(user, :video, video4.id, category2.id)

      variables = %{userId: user.id, categoryId: category.id, filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoritedVideos")
      results2 = guest_conn |> query_result(@query, variables, "favoritedVideos")

      assert results["totalCount"] == 3
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(video1.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(video2.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(video3.id)))

      assert results == results2
    end
  end
end
