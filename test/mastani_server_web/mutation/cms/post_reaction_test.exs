defmodule MastaniServer.Test.Mutation.PostReaction do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn post user)a}
  end

  describe "[post star]" do
    @query """
    mutation($id: ID!, $action: String!, $thread: CmsThread!) {
      reaction(id: $id, action: $action, thread: $thread) {
        id
      }
    }
    """
    test "login user can star a post", ~m(user_conn post)a do
      variables = %{id: post.id, thread: "POST", action: "STAR"}
      created = user_conn |> mutation_result(@query, variables, "reaction")

      assert created["id"] == to_string(post.id)
    end

    test "unauth user star a post fails", ~m(guest_conn post)a do
      variables = %{id: post.id, thread: "POST", action: "STAR"}

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
    test "login user can undo star a post", ~m(user_conn post user)a do
      {:ok, _} = CMS.reaction(:post, :star, post.id, user)

      variables = %{id: post.id, thread: "POST", action: "STAR"}
      updated = user_conn |> mutation_result(@query, variables, "undoReaction")

      assert updated["id"] == to_string(post.id)
    end

    test "unauth user undo star a post fails", ~m(guest_conn post)a do
      variables = %{id: post.id, thread: "POST", action: "STAR"}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
