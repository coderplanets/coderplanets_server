defmodule GroupherServer.Test.Query.ArticleComment do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn post job user)a}
  end

  describe "[post comment]" do
    @query """
      query($id: ID!, $thread: CmsThread, $filter: CommentsFilter!) {
        pagedArticleComments(id: $id, thread: $thread, filter: $filter) {
          entries {
            id
            bodyHtml
            author {
              id
              nickname
            }
          }
          totalPages
          totalCount
          pageSize
          pageNumber
        }
    }
    """
    @tag :wip2
    test "guest user can get paged comment for post", ~m(guest_conn post user)a do
      comment = "test comment"
      totalCount = 30
      thread = :post

      Enum.reduce(1..totalCount, [], fn _, acc ->
        {:ok, value} = CMS.write_comment(thread, post.id, comment, user)

        acc ++ [value]
      end)

      variables = %{id: post.id, thread: "POST", filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedArticleComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == totalCount
    end

    @tag :wip2
    test "guest user can get paged comment for job", ~m(guest_conn job user)a do
      comment = "test comment"
      totalCount = 30
      thread = :job

      Enum.reduce(1..totalCount, [], fn _, acc ->
        {:ok, value} = CMS.write_comment(thread, job.id, comment, user)

        acc ++ [value]
      end)

      variables = %{id: job.id, thread: "JOB", filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedArticleComments")

      IO.inspect(results, label: "results-")

      # assert results |> is_valid_pagination?
      # assert results["totalCount"] == totalCount
    end
  end
end
