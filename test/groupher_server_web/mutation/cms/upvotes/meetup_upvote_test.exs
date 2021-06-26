defmodule GroupherServer.Test.Mutation.Upvotes.MeetupUpvote do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, meetup} = db_insert(:meetup)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn meetup user)a}
  end

  describe "[meetup upvote]" do
    @query """
    mutation($id: ID!) {
      upvoteMeetup(id: $id) {
        id
      }
    }
    """

    test "login user can upvote a meetup", ~m(user_conn meetup)a do
      variables = %{id: meetup.id}
      created = user_conn |> mutation_result(@query, variables, "upvoteMeetup")

      assert created["id"] == to_string(meetup.id)
    end

    test "unauth user upvote a meetup fails", ~m(guest_conn meetup)a do
      variables = %{id: meetup.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!) {
      undoUpvoteMeetup(id: $id) {
        id
      }
    }
    """

    test "login user can undo upvote to a meetup", ~m(user_conn meetup user)a do
      {:ok, _} = CMS.upvote_article(:meetup, meetup.id, user)

      variables = %{id: meetup.id}
      updated = user_conn |> mutation_result(@query, variables, "undoUpvoteMeetup")

      assert updated["id"] == to_string(meetup.id)
    end

    test "unauth user undo upvote a meetup fails", ~m(guest_conn meetup)a do
      variables = %{id: meetup.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
