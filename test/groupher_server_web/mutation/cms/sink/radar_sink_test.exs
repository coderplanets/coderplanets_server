defmodule GroupherServer.Test.Mutation.Sink.RadarSink do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Radar

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, radar} = CMS.create_article(community, :radar, mock_attrs(:radar), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn community radar user)a}
  end

  describe "[radar sink]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      sinkRadar(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can sink a radar", ~m(community radar)a do
      variables = %{id: radar.id, communityId: community.id}
      passport_rules = %{community.raw => %{"radar.sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "sinkRadar")
      assert result["id"] == to_string(radar.id)

      {:ok, radar} = ORM.find(Radar, radar.id)
      assert radar.meta.is_sinked
      assert radar.active_at == radar.inserted_at
    end

    test "unauth user sink a radar fails", ~m(guest_conn community radar)a do
      variables = %{id: radar.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoSinkRadar(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can undo sink to a radar", ~m(community radar)a do
      variables = %{id: radar.id, communityId: community.id}

      passport_rules = %{community.raw => %{"radar.undo_sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, _} = CMS.sink_article(:radar, radar.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoSinkRadar")
      assert updated["id"] == to_string(radar.id)

      {:ok, radar} = ORM.find(Radar, radar.id)
      assert not radar.meta.is_sinked
    end

    test "unauth user undo sink a radar fails", ~m(guest_conn community radar)a do
      variables = %{id: radar.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
