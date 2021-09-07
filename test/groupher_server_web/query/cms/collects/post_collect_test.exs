defmodule GroupherServer.Test.Query.Collects.PostCollect do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn user user2 post)a}
  end

  describe "[collect users]" do
    @query """
    query(
      $id: ID!
      $thread: Thread
      $filter: PagedFilter!
    ) {
      collectedUsers(id: $id, thread: $thread, filter: $filter) {
        entries {
          login
          avatar
          nickname
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """

    test "guest can get collected users list after collect a post",
         ~m(guest_conn post user user2)a do
      {:ok, _} = CMS.collect_article(:post, post.id, user)
      {:ok, _} = CMS.collect_article(:post, post.id, user2)

      variables = %{id: post.id, thread: "POST", filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "collectedUsers")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 2

      assert user_exist_in?(user, results["entries"])
      assert user_exist_in?(user2, results["entries"])
    end
  end
end
