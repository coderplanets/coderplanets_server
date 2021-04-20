defmodule GroupherServer.Test.Query.ArticleComment do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn post job user user2)a}
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
            upvotesCount
            insertedAt
            updatedAt
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

      assert results["totalCount"] == total_count + 2
    end

    @tag :wip
    test "guest user can get paged comment with floor it", ~m(guest_conn post user)a do
      total_count = 20
      thread = :post

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_article_comment(thread, post.id, "test comment", user)

        acc ++ [comment]
      end)

      variables = %{id: post.id, thread: "POST", filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedArticleComments")

      assert results["entries"] |> List.first() |> Map.get("floor") == 1
      assert results["entries"] |> List.last() |> Map.get("floor") == 10
    end

    @tag :wip2
    test "the comments is loaded in asc order", ~m(guest_conn post user)a do
      page_size = 10
      thread = :post

      {:ok, comment} = CMS.create_article_comment(thread, post.id, "test comment #{1}", user)
      Process.sleep(1000)
      {:ok, _comment2} = CMS.create_article_comment(thread, post.id, "test comment #{2}", user)
      Process.sleep(1000)
      {:ok, comment3} = CMS.create_article_comment(thread, post.id, "test comment #{3}", user)

      variables = %{id: post.id, thread: "POST", filter: %{page: 1, size: page_size}}
      results = guest_conn |> query_result(@query, variables, "pagedArticleComments")

      assert List.first(results["entries"]) |> Map.get("id") == to_string(comment.id)
      assert List.last(results["entries"]) |> Map.get("id") == to_string(comment3.id)
    end

    @tag :wip2
    test "guest user can get paged comment with upvotes_count", ~m(guest_conn post user user2)a do
      total_count = 10
      page_size = 10
      thread = :post

      all_comment =
        Enum.reduce(1..total_count, [], fn i, acc ->
          {:ok, comment} = CMS.create_article_comment(thread, post.id, "test comment #{i}", user)
          Process.sleep(1000)
          acc ++ [comment]
        end)

      upvote_comment = all_comment |> Enum.at(3)
      upvote_comment2 = all_comment |> Enum.at(4)
      {:ok, _} = CMS.upvote_article_comment(upvote_comment.id, user)
      {:ok, _} = CMS.upvote_article_comment(upvote_comment2.id, user)
      {:ok, _} = CMS.upvote_article_comment(upvote_comment2.id, user2)

      variables = %{id: post.id, thread: "POST", filter: %{page: 1, size: page_size}}
      results = guest_conn |> query_result(@query, variables, "pagedArticleComments")

      assert results["entries"] |> Enum.at(3) |> Map.get("upvotesCount") == 1
      assert results["entries"] |> Enum.at(4) |> Map.get("upvotesCount") == 2
      assert results["entries"] |> List.first() |> Map.get("upvotesCount") == 0
      assert results["entries"] |> List.last() |> Map.get("upvotesCount") == 0
    end
  end
end
