defmodule GroupherServer.Test.Mutation.Upvotes.GuideUpvote do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, guide} = db_insert(:guide)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn guide user)a}
  end

  describe "[guide upvote]" do
    @query """
    mutation($id: ID!) {
      upvoteGuide(id: $id) {
        id
      }
    }
    """

    test "login user can upvote a guide", ~m(user_conn guide)a do
      variables = %{id: guide.id}
      created = user_conn |> mutation_result(@query, variables, "upvoteGuide")

      assert created["id"] == to_string(guide.id)
    end

    test "unauth user upvote a guide fails", ~m(guest_conn guide)a do
      variables = %{id: guide.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!) {
      undoUpvoteGuide(id: $id) {
        id
      }
    }
    """

    test "login user can undo upvote to a guide", ~m(user_conn guide user)a do
      {:ok, _} = CMS.upvote_article(:guide, guide.id, user)

      variables = %{id: guide.id}
      updated = user_conn |> mutation_result(@query, variables, "undoUpvoteGuide")

      assert updated["id"] == to_string(guide.id)
    end

    test "unauth user undo upvote a guide fails", ~m(guest_conn guide)a do
      variables = %{id: guide.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
