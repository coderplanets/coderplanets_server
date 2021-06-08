defmodule GroupherServer.Test.Mutation.Upvotes.BlogUpvote do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, blog} = db_insert(:blog)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn blog user)a}
  end

  describe "[blog upvote]" do
    @query """
    mutation($id: ID!) {
      upvoteBlog(id: $id) {
        id
      }
    }
    """

    test "login user can upvote a blog", ~m(user_conn blog)a do
      variables = %{id: blog.id}
      created = user_conn |> mutation_result(@query, variables, "upvoteBlog")

      assert created["id"] == to_string(blog.id)
    end

    test "unauth user upvote a blog fails", ~m(guest_conn blog)a do
      variables = %{id: blog.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!) {
      undoUpvoteBlog(id: $id) {
        id
      }
    }
    """

    test "login user can undo upvote to a blog", ~m(user_conn blog user)a do
      {:ok, _} = CMS.upvote_article(:blog, blog.id, user)

      variables = %{id: blog.id}
      updated = user_conn |> mutation_result(@query, variables, "undoUpvoteBlog")

      assert updated["id"] == to_string(blog.id)
    end

    test "unauth user undo upvote a blog fails", ~m(guest_conn blog)a do
      variables = %{id: blog.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
