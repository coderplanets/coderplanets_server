defmodule GroupherServer.Test.Mutation.Sink.MeetupSink do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Meetup

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, meetup} = CMS.create_article(community, :meetup, mock_attrs(:meetup), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn community meetup user)a}
  end

  describe "[meetup sink]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      sinkMeetup(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can sink a meetup", ~m(community meetup)a do
      variables = %{id: meetup.id, communityId: community.id}
      passport_rules = %{community.raw => %{"meetup.sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "sinkMeetup")
      assert result["id"] == to_string(meetup.id)

      {:ok, meetup} = ORM.find(Meetup, meetup.id)
      assert meetup.meta.is_sinked
      assert meetup.active_at == meetup.inserted_at
    end

    test "unauth user sink a meetup fails", ~m(guest_conn community meetup)a do
      variables = %{id: meetup.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoSinkMeetup(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can undo sink to a meetup", ~m(community meetup)a do
      variables = %{id: meetup.id, communityId: community.id}

      passport_rules = %{community.raw => %{"meetup.undo_sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, _} = CMS.sink_article(:meetup, meetup.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoSinkMeetup")
      assert updated["id"] == to_string(meetup.id)

      {:ok, meetup} = ORM.find(Meetup, meetup.id)
      assert not meetup.meta.is_sinked
    end

    test "unauth user undo sink a meetup fails", ~m(guest_conn community meetup)a do
      variables = %{id: meetup.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
