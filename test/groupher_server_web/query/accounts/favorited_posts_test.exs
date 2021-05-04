# defmodule GroupherServer.Test.Query.Accounts.FavritedPosts do
#   use GroupherServer.TestTools

#   alias GroupherServer.CMS

#   @total_count 20

#   setup do
#     {:ok, user} = db_insert(:user)

#     {:ok, posts} = db_insert_multi(:post, @total_count)

#     guest_conn = simu_conn(:guest)
#     user_conn = simu_conn(:user, user)

#     {:ok, ~m(guest_conn user_conn user posts)a}
#   end

#   describe "[account favorited posts]" do
#     @query """
#     query($filter: PagedFilter!) {
#       user {
#         id
#         favoritedPosts(filter: $filter) {
#           entries {
#             id
#           }
#           totalCount
#         }
#         favoritedPostsCount
#       }
#     }
#     """
#     test "login user can get it's own favoritedPosts", ~m(user_conn user posts)a do
#       Enum.each(posts, fn post ->
#         {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
#       end)

#       random_id = posts |> Enum.shuffle() |> List.first() |> Map.get(:id) |> to_string

#       variables = %{filter: %{page: 1, size: 20}}
#       results = user_conn |> query_result(@query, variables, "user")
#       assert results["favoritedPosts"] |> Map.get("totalCount") == @total_count
#       assert results["favoritedPostsCount"] == @total_count

#       assert results["favoritedPosts"]
#              |> Map.get("entries")
#              |> Enum.any?(&(&1["id"] == random_id))
#     end

#     @query """
#     query($userId: ID!, $categoryId: ID, $filter: PagedFilter!) {
#       favoritedPosts(userId: $userId, categoryId: $categoryId, filter: $filter) {
#         entries {
#           id
#         }
#         totalCount
#       }
#     }
#     """
#     test "other user can get other user's paged favoritedPosts",
#          ~m(user_conn guest_conn posts)a do
#       {:ok, user} = db_insert(:user)

#       Enum.each(posts, fn post ->
#         {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
#       end)

#       variables = %{userId: user.id, filter: %{page: 1, size: 20}}
#       results = user_conn |> query_result(@query, variables, "favoritedPosts")
#       results2 = guest_conn |> query_result(@query, variables, "favoritedPosts")

#       assert results["totalCount"] == @total_count
#       assert results2["totalCount"] == @total_count
#     end

#     alias GroupherServer.Accounts

#     test "can get paged favoritedPosts on a spec category", ~m(user_conn guest_conn posts)a do
#       {:ok, user} = db_insert(:user)

#       Enum.each(posts, fn post ->
#         {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
#       end)

#       post1 = Enum.at(posts, 0)
#       post2 = Enum.at(posts, 1)
#       post3 = Enum.at(posts, 2)
#       post4 = Enum.at(posts, 4)

#       test_category = "test category"
#       test_category2 = "test category2"

#       {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
#       {:ok, category2} = Accounts.create_favorite_category(user, %{title: test_category2})

#       {:ok, _favorites_category} = Accounts.set_favorites(user, :post, post1.id, category.id)
#       {:ok, _favorites_category} = Accounts.set_favorites(user, :post, post2.id, category.id)
#       {:ok, _favorites_category} = Accounts.set_favorites(user, :post, post3.id, category.id)
#       {:ok, _favorites_category} = Accounts.set_favorites(user, :post, post4.id, category2.id)

#       variables = %{userId: user.id, categoryId: category.id, filter: %{page: 1, size: 20}}
#       results = user_conn |> query_result(@query, variables, "favoritedPosts")
#       results2 = guest_conn |> query_result(@query, variables, "favoritedPosts")

#       assert results["totalCount"] == 3
#       assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post1.id)))
#       assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post2.id)))
#       assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post3.id)))

#       assert results == results2
#     end
#   end
# end
