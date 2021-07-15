defmodule GroupherServer.Test.Mutation.Sink.DrinkSink do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Drink

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, drink} = CMS.create_article(community, :drink, mock_attrs(:drink), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn community drink user)a}
  end

  describe "[drink sink]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      sinkDrink(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can sink a drink", ~m(community drink)a do
      variables = %{id: drink.id, communityId: community.id}
      passport_rules = %{community.raw => %{"drink.sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "sinkDrink")
      assert result["id"] == to_string(drink.id)

      {:ok, drink} = ORM.find(Drink, drink.id)
      assert drink.meta.is_sinked
      assert drink.active_at == drink.inserted_at
    end

    test "unauth user sink a drink fails", ~m(guest_conn community drink)a do
      variables = %{id: drink.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoSinkDrink(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can undo sink to a drink", ~m(community drink)a do
      variables = %{id: drink.id, communityId: community.id}

      passport_rules = %{community.raw => %{"drink.undo_sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, _} = CMS.sink_article(:drink, drink.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoSinkDrink")
      assert updated["id"] == to_string(drink.id)

      {:ok, drink} = ORM.find(Drink, drink.id)
      assert not drink.meta.is_sinked
    end

    test "unauth user undo sink a drink fails", ~m(guest_conn community drink)a do
      variables = %{id: drink.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
