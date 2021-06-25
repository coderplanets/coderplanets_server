defmodule GroupherServer.Test.Mutation.Upvotes.WorksUpvote do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, works} = db_insert(:works)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn works user)a}
  end

  describe "[works upvote]" do
    @query """
    mutation($id: ID!) {
      upvoteWorks(id: $id) {
        id
      }
    }
    """

    test "login user can upvote a works", ~m(user_conn works)a do
      variables = %{id: works.id}
      created = user_conn |> mutation_result(@query, variables, "upvoteWorks")

      assert created["id"] == to_string(works.id)
    end

    test "unauth user upvote a works fails", ~m(guest_conn works)a do
      variables = %{id: works.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!) {
      undoUpvoteWorks(id: $id) {
        id
      }
    }
    """

    test "login user can undo upvote to a works", ~m(user_conn works user)a do
      {:ok, _} = CMS.upvote_article(:works, works.id, user)

      variables = %{id: works.id}
      updated = user_conn |> mutation_result(@query, variables, "undoUpvoteWorks")

      assert updated["id"] == to_string(works.id)
    end

    test "unauth user undo upvote a works fails", ~m(guest_conn works)a do
      variables = %{id: works.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
