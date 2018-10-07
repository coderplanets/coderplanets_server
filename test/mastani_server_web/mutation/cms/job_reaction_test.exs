defmodule MastaniServer.Test.Mutation.JobReaction do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn job user)a}
  end

  describe "[job favorite]" do
    @query """
    mutation($id: ID!, $action: String!, $thread: CmsThread!) {
      reaction(id: $id, action: $action, thread: $thread) {
        id
      }
    }
    """
    @tag :wip
    test "login user can favorite a job", ~m(user_conn job)a do
      variables = %{id: job.id, thread: "JOB", action: "FAVORITE"}
      created = user_conn |> mutation_result(@query, variables, "reaction")

      assert created["id"] == to_string(job.id)
    end

    @tag :wip
    test "unauth user favorite a job fails", ~m(guest_conn job)a do
      variables = %{id: job.id, thread: "JOB", action: "FAVORITE"}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $action: String!, $thread: CmsThread!) {
      undoReaction(id: $id, action: $action, thread: $thread) {
        id
      }
    }
    """
    @tag :wip
    test "login user can undo favorite a job", ~m(user_conn job user)a do
      {:ok, _} = CMS.reaction(:job, :favorite, job.id, user)

      variables = %{id: job.id, thread: "JOB", action: "FAVORITE"}
      updated = user_conn |> mutation_result(@query, variables, "undoReaction")

      assert updated["id"] == to_string(job.id)
    end

    @tag :wip
    test "unauth user undo favorite a job fails", ~m(guest_conn job)a do
      variables = %{id: job.id, thread: "JOB", action: "FAVORITE"}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end

  describe "[job star]" do
    @query """
    mutation($id: ID!, $action: String!, $thread: CmsThread!) {
      reaction(id: $id, action: $action, thread: $thread) {
        id
      }
    }
    """
    @tag :wip
    test "login user can star a job", ~m(user_conn job)a do
      variables = %{id: job.id, thread: "JOB", action: "STAR"}
      created = user_conn |> mutation_result(@query, variables, "reaction")

      assert created["id"] == to_string(job.id)
    end

    @tag :wip
    test "unauth user star a job fails", ~m(guest_conn job)a do
      variables = %{id: job.id, thread: "JOB", action: "STAR"}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $action: String!, $thread: CmsThread!) {
      undoReaction(id: $id, action: $action, thread: $thread) {
        id
      }
    }
    """
    @tag :wip
    test "login user can undo star a job", ~m(user_conn job user)a do
      {:ok, _} = CMS.reaction(:job, :star, job.id, user)

      variables = %{id: job.id, thread: "JOB", action: "STAR"}
      updated = user_conn |> mutation_result(@query, variables, "undoReaction")

      assert updated["id"] == to_string(job.id)
    end

    @tag :wip
    test "unauth user undo star a job fails", ~m(guest_conn job)a do
      variables = %{id: job.id, thread: "JOB", action: "STAR"}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
