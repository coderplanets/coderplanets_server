defmodule MastaniServer.Test.Mutation.VideoReaction do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, video} = db_insert(:video)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn video user)a}
  end

  describe "[video star]" do
    @query """
    mutation($id: ID!, $action: String!, $thread: CmsThread!) {
      reaction(id: $id, action: $action, thread: $thread) {
        id
      }
    }
    """
    test "login user can star a video", ~m(user_conn video)a do
      variables = %{id: video.id, thread: "VIDEO", action: "STAR"}
      created = user_conn |> mutation_result(@query, variables, "reaction")

      assert created["id"] == to_string(video.id)
    end

    test "unauth user star a video fails", ~m(guest_conn video)a do
      variables = %{id: video.id, thread: "VIDEO", action: "STAR"}

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
    test "login user can undo star a video", ~m(user_conn video user)a do
      {:ok, _} = CMS.reaction(:video, :star, video.id, user)

      variables = %{id: video.id, thread: "VIDEO", action: "STAR"}
      updated = user_conn |> mutation_result(@query, variables, "undoReaction")

      assert updated["id"] == to_string(video.id)
    end

    test "unauth user undo star a video fails", ~m(guest_conn video)a do
      variables = %{id: video.id, thread: "VIDEO", action: "STAR"}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
