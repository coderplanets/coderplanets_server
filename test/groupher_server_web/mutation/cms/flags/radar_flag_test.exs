defmodule GroupherServer.Test.Mutation.Flags.RadarFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Community

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, radar} = CMS.create_article(community, :radar, mock_attrs(:radar), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community user radar)a}
  end

  describe "[mutation radar flag curd]" do
    @query """
    mutation($id: ID!){
      markDeleteRadar(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can markDelete radar", ~m(radar)a do
      variables = %{id: radar.id}

      passport_rules = %{"radar.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "markDeleteRadar")

      assert updated["id"] == to_string(radar.id)
      assert updated["markDelete"] == true
    end

    test "mark delete radar should update radar's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, radar} = CMS.create_article(community, :radar, mock_attrs(:radar), user)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.radars_count == 1

      variables = %{id: radar.id}
      passport_rules = %{"radar.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@query, variables, "markDeleteRadar")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.radars_count == 0
    end

    test "unauth user markDelete radar fails", ~m(user_conn guest_conn radar)a do
      variables = %{id: radar.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoMarkDeleteRadar(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can undo markDelete radar", ~m(radar)a do
      variables = %{id: radar.id}

      {:ok, _} = CMS.mark_delete_article(:radar, radar.id)

      passport_rules = %{"radar.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoMarkDeleteRadar")

      assert updated["id"] == to_string(radar.id)
      assert updated["markDelete"] == false
    end

    test "undo mark delete radar should update radar's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, radar} = CMS.create_article(community, :radar, mock_attrs(:radar), user)

      {:ok, _} = CMS.mark_delete_article(:radar, radar.id)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.radars_count == 0

      variables = %{id: radar.id}
      passport_rules = %{"radar.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)
      rule_conn |> mutation_result(@query, variables, "undoMarkDeleteRadar")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.radars_count == 1
    end

    test "unauth user undo markDelete radar fails", ~m(user_conn guest_conn radar)a do
      variables = %{id: radar.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinRadar(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "auth user can pin radar", ~m(community radar)a do
      variables = %{id: radar.id, communityId: community.id}

      passport_rules = %{community.raw => %{"radar.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinRadar")

      assert updated["id"] == to_string(radar.id)
    end

    test "unauth user pin radar fails", ~m(user_conn guest_conn community radar)a do
      variables = %{id: radar.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinRadar(id: $id, communityId: $communityId) {
        id
        isPinned
      }
    }
    """

    test "auth user can undo pin radar", ~m(community radar)a do
      variables = %{id: radar.id, communityId: community.id}

      passport_rules = %{community.raw => %{"radar.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_article(:radar, radar.id, community.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinRadar")

      assert updated["id"] == to_string(radar.id)
    end

    test "unauth user undo pin radar fails", ~m(user_conn guest_conn community radar)a do
      variables = %{id: radar.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
