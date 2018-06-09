defmodule MastaniServer.Test.Query.JobCommentTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.Test.ConnSimulator
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  alias MastaniServer.{CMS, Accounts}

  setup do
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn job user)a}
  end

  # TODO: user can get specific user's replies :list_replies
  describe "[job comment]" do
    @query """
    query($thread: CmsThread, $id: ID!, $filter: CommentsFilter!) {
      comments(thread: $thread, id: $id, filter: $filter) {
        entries {
          id
          body
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "guest user can get a paged comment", ~m(guest_conn job user)a do
      content = "test comment"

      Enum.reduce(1..30, [], fn _, acc ->
        {:ok, value} = CMS.create_comment(:job, job.id, %Accounts.User{id: user.id}, content)

        acc ++ [value]
      end)

      variables = %{thread: "JOB", id: job.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "comments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 30
    end

    @query """
    query($thread: CmsThread, $id: ID!, $filter: PagedFilter!) {
      comments(thread: $thread, id: $id, filter: $filter) {
        entries {
          id
          body
          replyTo {
            id
            body
          }
          repliesCount
          replies {
            id
            body
          }
        }
      }
    }
    """
    test "guest user can get replies info", ~m(guest_conn job user)a do
      body = "test comment"

      {:ok, comment} = CMS.create_comment(:job, job.id, %Accounts.User{id: user.id}, body)

      {:ok, reply} =
        CMS.reply_comment(:job, comment.id, %Accounts.User{id: user.id}, "reply body")

      variables = %{thread: "JOB", id: job.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "comments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      found_reply =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(reply.id))) |> List.first()

      # author = found |> Map.get("author")
      assert found["repliesCount"] == 1
      assert found["replies"] |> Enum.any?(&(&1["id"] == to_string(reply.id)))
      assert found["replyTo"] == nil
      assert found_reply["replyTo"] |> Map.get("id") == to_string(comment.id)
    end
  end
end
