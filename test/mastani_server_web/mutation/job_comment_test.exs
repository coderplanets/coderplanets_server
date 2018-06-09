defmodule MastaniServer.Test.Mutation.JobCommentTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.Test.ConnSimulator
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  alias MastaniServer.{CMS, Accounts}
  alias Helper.ORM

  setup do
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)

    # {:ok, user2} = db_insert(:user)
    # {:ok, post2} = db_insert(:post)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, comment} = CMS.create_comment(:job, job.id, %Accounts.User{id: user.id}, "test comment")

    {:ok, ~m(user_conn guest_conn job user comment)a}
  end

  describe "[job comment CURD]" do
    @create_comment_query """
    mutation($thread: CmsThread, $id: ID!, $body: String!) {
      createComment(thread: $thread, id: $id, body: $body) {
        id
        body
      }
    }
    """
    test "login user can create comment to a job", ~m(user_conn job)a do
      variables = %{thread: "JOB", id: job.id, body: "this a comment"}
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      {:ok, found} = ORM.find(CMS.JobComment, created["id"])

      assert created["id"] == to_string(found.id)
    end

    test "guest user create comment fails", ~m(guest_conn job)a do
      variables = %{thread: "JOB", id: job.id, body: "this a comment"}

      assert guest_conn |> mutation_get_error?(@create_comment_query, variables)
    end

    @delete_comment_query """
    mutation($thread: CmsThread, $id: ID!) {
      deleteComment(thread: $thread, id: $id) {
        id
        body
      }
    }
    """
    test "comment owner can delete comment", ~m(user job)a do
      variables = %{thread: "JOB", id: job.id, body: "this a comment"}

      user_conn = simu_conn(:user, user)
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      deleted =
        user_conn
        |> mutation_result(
          @delete_comment_query,
          %{thread: "JOB", id: created["id"]},
          "deleteComment"
        )

      assert deleted["id"] == created["id"]
    end

    test "unauth user delete comment fails", ~m(user_conn guest_conn job)a do
      variables = %{thread: "JOB", id: job.id, body: "this a comment"}
      {:ok, owner} = db_insert(:user)
      owner_conn = simu_conn(:user, owner)
      created = owner_conn |> mutation_result(@create_comment_query, variables, "createComment")

      variables = %{id: created["id"]}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@delete_comment_query, variables)
      assert guest_conn |> mutation_get_error?(@delete_comment_query, variables)
      assert rule_conn |> mutation_get_error?(@delete_comment_query, variables)
    end

    @reply_comment_query """
    mutation($thread: CmsThread!, $id: ID!, $body: String!) {
      replyComment(thread: $thread, id: $id, body: $body) {
        id
        body
        replyTo {
          id
          body
        }
      }
    }
    """
    test "login user can reply to a exsit comment", ~m(user_conn comment)a do
      variables = %{thread: "JOB", id: comment.id, body: "this a reply"}
      replied = user_conn |> mutation_result(@reply_comment_query, variables, "replyComment")

      assert replied["replyTo"] |> Map.get("id") == to_string(comment.id)
    end

    test "guest user reply comment fails", ~m(guest_conn comment)a do
      variables = %{thread: "JOB", id: comment.id, body: "this a reply"}

      assert guest_conn |> mutation_get_error?(@reply_comment_query, variables)
    end

    test "TODO owner can NOT delete comment when comment has replies" do
    end

    test "TODO owner can NOT edit comment when comment has replies" do
    end

    test "TODO owner can NOT delete comment when comment has created after 3 hours" do
    end
  end
end
