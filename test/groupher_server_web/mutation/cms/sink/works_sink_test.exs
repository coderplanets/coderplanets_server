defmodule GroupherServer.Test.Mutation.Sink.WorksSink do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Works

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, works} = CMS.create_article(community, :works, mock_attrs(:works), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn community works user)a}
  end

  describe "[works sink]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      sinkWorks(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can sink a works", ~m(community works)a do
      variables = %{id: works.id, communityId: community.id}
      passport_rules = %{community.raw => %{"works.sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "sinkWorks")
      assert result["id"] == to_string(works.id)

      {:ok, works} = ORM.find(Works, works.id)
      assert works.meta.is_sinked
      assert works.active_at == works.inserted_at
    end

    test "unauth user sink a works fails", ~m(guest_conn community works)a do
      variables = %{id: works.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoSinkWorks(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can undo sink to a works", ~m(community works)a do
      variables = %{id: works.id, communityId: community.id}

      passport_rules = %{community.raw => %{"works.undo_sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, _} = CMS.sink_article(:works, works.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoSinkWorks")
      assert updated["id"] == to_string(works.id)

      {:ok, works} = ORM.find(Works, works.id)
      assert not works.meta.is_sinked
    end

    test "unauth user undo sink a works fails", ~m(guest_conn community works)a do
      variables = %{id: works.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
