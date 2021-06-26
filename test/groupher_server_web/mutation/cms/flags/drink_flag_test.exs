defmodule GroupherServer.Test.Mutation.Flags.DrinkFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Community

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, drink} = CMS.create_article(community, :drink, mock_attrs(:drink), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community user drink)a}
  end

  describe "[mutation drink flag curd]" do
    @query """
    mutation($id: ID!){
      markDeleteDrink(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can markDelete drink", ~m(drink)a do
      variables = %{id: drink.id}

      passport_rules = %{"drink.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "markDeleteDrink")

      assert updated["id"] == to_string(drink.id)
      assert updated["markDelete"] == true
    end

    test "mark delete drink should update drink's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, drink} = CMS.create_article(community, :drink, mock_attrs(:drink), user)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.drinks_count == 1

      variables = %{id: drink.id}
      passport_rules = %{"drink.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@query, variables, "markDeleteDrink")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.drinks_count == 0
    end

    test "unauth user markDelete drink fails", ~m(user_conn guest_conn drink)a do
      variables = %{id: drink.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoMarkDeleteDrink(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can undo markDelete drink", ~m(drink)a do
      variables = %{id: drink.id}

      {:ok, _} = CMS.mark_delete_article(:drink, drink.id)

      passport_rules = %{"drink.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoMarkDeleteDrink")

      assert updated["id"] == to_string(drink.id)
      assert updated["markDelete"] == false
    end

    test "undo mark delete drink should update drink's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, drink} = CMS.create_article(community, :drink, mock_attrs(:drink), user)

      {:ok, _} = CMS.mark_delete_article(:drink, drink.id)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.drinks_count == 0

      variables = %{id: drink.id}
      passport_rules = %{"drink.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)
      rule_conn |> mutation_result(@query, variables, "undoMarkDeleteDrink")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.drinks_count == 1
    end

    test "unauth user undo markDelete drink fails", ~m(user_conn guest_conn drink)a do
      variables = %{id: drink.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinDrink(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "auth user can pin drink", ~m(community drink)a do
      variables = %{id: drink.id, communityId: community.id}

      passport_rules = %{community.raw => %{"drink.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinDrink")

      assert updated["id"] == to_string(drink.id)
    end

    test "unauth user pin drink fails", ~m(user_conn guest_conn community drink)a do
      variables = %{id: drink.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinDrink(id: $id, communityId: $communityId) {
        id
        isPinned
      }
    }
    """

    test "auth user can undo pin drink", ~m(community drink)a do
      variables = %{id: drink.id, communityId: community.id}

      passport_rules = %{community.raw => %{"drink.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_article(:drink, drink.id, community.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinDrink")

      assert updated["id"] == to_string(drink.id)
    end

    test "unauth user undo pin drink fails", ~m(user_conn guest_conn community drink)a do
      variables = %{id: drink.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
