defmodule GroupherServer.Test.Mutation.Upvotes.PostUpvote do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn post user)a}
  end

  describe "[post upvote]" do
    @query """
    mutation($id: ID!) {
      upvotePost(id: $id) {
        id
        meta {
          latestUpvotedUsers {
            login
          }
        }
      }
    }
    """
    test "login user can upvote a post", ~m(user_conn user post)a do
      variables = %{id: post.id}
      created = user_conn |> mutation_result(@query, variables, "upvotePost")

      assert user_exist_in?(user, get_in(created, ["meta", "latestUpvotedUsers"]))
      assert created["id"] == to_string(post.id)
    end

    test "unauth user upvote a post fails", ~m(guest_conn post)a do
      variables = %{id: post.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!) {
      undoUpvotePost(id: $id) {
        id
        meta {
          latestUpvotedUsers {
            login
          }
        }
      }
    }
    """
    test "login user can undo upvote to a post", ~m(user_conn post user)a do
      {:ok, _} = CMS.upvote_article(:post, post.id, user)

      variables = %{id: post.id}
      updated = user_conn |> mutation_result(@query, variables, "undoUpvotePost")

      assert not user_exist_in?(user, get_in(updated, ["meta", "latestUpvotedUsers"]))
      assert updated["id"] == to_string(post.id)
    end

    test "unauth user undo upvote a post fails", ~m(guest_conn post)a do
      variables = %{id: post.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
