defmodule GroupherServer.Test.Query.Accounts.PublishedComments do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn community user)a}
  end

  describe "[account published comments on post]" do
    @query """
    query($userId: ID!, $filter: PagedFilter!) {
      publishedPostComments(userId: $userId, filter: $filter) {
        entries {
          id
          body
          author {
            id
          }
          post {
            id
            title
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get paged published comments on post", ~m(guest_conn user community)a do
      {:ok, post} = db_insert(:post)

      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          body = "this is a test comment"

          {:ok, comment} =
            CMS.create_comment(:post, post.id, %{community: community.raw, body: body}, user)

          acc ++ [comment]
        end)

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id) |> to_string

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "publishedPostComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert results["entries"] |> Enum.all?(&(&1["post"]["id"] == to_string(post.id)))
      assert results["entries"] |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == random_comment_id))
    end
  end
end
