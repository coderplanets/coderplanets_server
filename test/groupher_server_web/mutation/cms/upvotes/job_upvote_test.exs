defmodule GroupherServer.Test.Mutation.Upvotes.JobUpvote do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn job user)a}
  end

  describe "[job upvote]" do
    @query """
    mutation($id: ID!) {
      upvoteJob(id: $id) {
        id
      }
    }
    """

    test "login user can upvote a job", ~m(user_conn job)a do
      variables = %{id: job.id}
      created = user_conn |> mutation_result(@query, variables, "upvoteJob")

      assert created["id"] == to_string(job.id)
    end

    test "unauth user upvote a job fails", ~m(guest_conn job)a do
      variables = %{id: job.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!) {
      undoUpvoteJob(id: $id) {
        id
      }
    }
    """

    test "login user can undo upvote to a job", ~m(user_conn job user)a do
      {:ok, _} = CMS.upvote_article(:job, job.id, user)

      variables = %{id: job.id}
      updated = user_conn |> mutation_result(@query, variables, "undoUpvoteJob")

      assert updated["id"] == to_string(job.id)
    end

    test "unauth user undo upvote a job fails", ~m(guest_conn job)a do
      variables = %{id: job.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
