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

  # describe "[article post comment operation]" do
  #   @tag :wip
  #   test "only author of the article can fold comment under the article" do
  #   end
  # end

  describe "[baisc article post comment]" do
    @query """
    query($id: ID!) {
      post(id: $id) {
        id
        title
        body
        commentParticipators{
          id
          nickname
        }
      }
    }
    """
    @tag :wip
    test "guest user can get comment participators after comment created",
         ~m(guest_conn post user)a do
      comment = "test comment"
      total_count = 3
      thread = :post

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, value} = CMS.create_article_comment(thread, post.id, comment, user)

        acc ++ [value]
      end)

      variables = %{id: post.id}
      results = guest_conn |> query_result(@query, variables, "post")

      comment_participators = results["commentParticipators"]
      assert is_list(comment_participators)
    end

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
            isPined
            floor
          }
          totalPages
          totalCount
          pageSize
          pageNumber
        }
    }
    """
    @tag :wip
    test "guest user can get paged comment for post", ~m(guest_conn post user)a do
      comment = "test comment"
      total_count = 30
      thread = :post

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, value} = CMS.create_article_comment(thread, post.id, comment, user)

        acc ++ [value]
      end)

      variables = %{id: post.id, thread: "POST", filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedArticleComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == total_count
    end

    @tag :wip
    test "guest user can get paged comment for job", ~m(guest_conn job user)a do
      comment = "test comment"
      total_count = 30
      thread = :job

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, value} = CMS.create_article_comment(thread, job.id, comment, user)

        acc ++ [value]
      end)

      variables = %{id: job.id, thread: "JOB", filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedArticleComments")

      # IO.inspect(results, label: "results-")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == total_count
    end

    @tag :wip
    test "guest user can get paged comment with pined comment in it", ~m(guest_conn post user)a do
      total_count = 20
      thread = :post

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_article_comment(thread, post.id, "test comment", user)

        acc ++ [comment]
      end)

      {:ok, comment} = CMS.create_article_comment(thread, post.id, "pined comment", user)
      {:ok, pined_comment} = CMS.pin_article_comment(comment.id)

      {:ok, comment} = CMS.create_article_comment(thread, post.id, "pined comment 2", user)
      {:ok, pined_comment2} = CMS.pin_article_comment(comment.id)

      variables = %{id: post.id, thread: "POST", filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedArticleComments")

      assert results["entries"] |> List.first() |> Map.get("id") == to_string(pined_comment.id)
      assert results["entries"] |> Enum.at(1) |> Map.get("id") == to_string(pined_comment2.id)

      assert results |> is_valid_pagination?
      assert results["totalCount"] == total_count + 2
    end

    @tag :wip2
    test "guest user can get paged comment with floor it", ~m(guest_conn post user)a do
      total_count = 20
      thread = :post

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_article_comment(thread, post.id, "test comment", user)

        acc ++ [comment]
      end)

      variables = %{id: post.id, thread: "POST", filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedArticleComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == total_count
    end
  end
end
