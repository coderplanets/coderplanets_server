defmodule MastaniServer.Test.Mutation.RepoReaction do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, repo} = db_insert(:repo)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn repo user)a}
  end

  describe "[repo favorite]" do
    @query """
    mutation($id: ID!, $action: String!, $thread: CmsThread!) {
      reaction(id: $id, action: $action, thread: $thread) {
        id
      }
    }
    """
    @tag :wip
    test "login user can star a repo", ~m(user_conn repo)a do
      variables = %{id: repo.id, thread: "REPO", action: "FAVORITE"}
      created = user_conn |> mutation_result(@query, variables, "reaction")

      assert created["id"] == to_string(repo.id)
    end

    @tag :wip
    test "unauth user star a repo fails", ~m(guest_conn repo)a do
      variables = %{id: repo.id, thread: "REPO", action: "FAVORITE"}

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
    test "login user can undo star a repo", ~m(user_conn repo user)a do
      {:ok, _} = CMS.reaction(:repo, :favorite, repo.id, user)

      variables = %{id: repo.id, thread: "REPO", action: "FAVORITE"}
      updated = user_conn |> mutation_result(@query, variables, "undoReaction")

      assert updated["id"] == to_string(repo.id)
    end

    @tag :wip
    test "unauth user undo star a repo fails", ~m(guest_conn repo)a do
      variables = %{id: repo.id, thread: "REPO", action: "FAVORITE"}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
