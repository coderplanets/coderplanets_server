defmodule GroupherServer.Test.Mutation.Sink.GuideSink do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Guide

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, guide} = CMS.create_article(community, :guide, mock_attrs(:guide), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn community guide user)a}
  end

  describe "[guide sink]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      sinkGuide(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can sink a guide", ~m(community guide)a do
      variables = %{id: guide.id, communityId: community.id}
      passport_rules = %{community.raw => %{"guide.sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "sinkGuide")
      assert result["id"] == to_string(guide.id)

      {:ok, guide} = ORM.find(Guide, guide.id)
      assert guide.meta.is_sinked
      assert guide.active_at == guide.inserted_at
    end

    test "unauth user sink a guide fails", ~m(guest_conn community guide)a do
      variables = %{id: guide.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoSinkGuide(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can undo sink to a guide", ~m(community guide)a do
      variables = %{id: guide.id, communityId: community.id}

      passport_rules = %{community.raw => %{"guide.undo_sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, _} = CMS.sink_article(:guide, guide.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoSinkGuide")
      assert updated["id"] == to_string(guide.id)

      {:ok, guide} = ORM.find(Guide, guide.id)
      assert not guide.meta.is_sinked
    end

    test "unauth user undo sink a guide fails", ~m(guest_conn community guide)a do
      variables = %{id: guide.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
