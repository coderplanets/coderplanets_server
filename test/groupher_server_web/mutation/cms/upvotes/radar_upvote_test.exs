defmodule GroupherServer.Test.Mutation.Upvotes.RadarUpvote do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, radar} = db_insert(:radar)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn radar user)a}
  end

  describe "[radar upvote]" do
    @query """
    mutation($id: ID!) {
      upvoteRadar(id: $id) {
        id
      }
    }
    """

    test "login user can upvote a radar", ~m(user_conn radar)a do
      variables = %{id: radar.id}
      created = user_conn |> mutation_result(@query, variables, "upvoteRadar")

      assert created["id"] == to_string(radar.id)
    end

    test "unauth user upvote a radar fails", ~m(guest_conn radar)a do
      variables = %{id: radar.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!) {
      undoUpvoteRadar(id: $id) {
        id
      }
    }
    """

    test "login user can undo upvote to a radar", ~m(user_conn radar user)a do
      {:ok, _} = CMS.upvote_article(:radar, radar.id, user)

      variables = %{id: radar.id}
      updated = user_conn |> mutation_result(@query, variables, "undoUpvoteRadar")

      assert updated["id"] == to_string(radar.id)
    end

    test "unauth user undo upvote a radar fails", ~m(guest_conn radar)a do
      variables = %{id: radar.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
