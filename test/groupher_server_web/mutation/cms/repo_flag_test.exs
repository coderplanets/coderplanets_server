defmodule GroupherServer.Test.Mutation.RepoFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, repo} = CMS.create_content(community, :repo, mock_attrs(:repo), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community repo)a}
  end

  describe "[mutation repo flag curd]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      trashRepo(id: $id, communityId: $communityId) {
        id
        trash
      }
    }
    """
    test "auth user can trash repo", ~m(community repo)a do
      variables = %{id: repo.id, communityId: community.id}

      passport_rules = %{community.raw => %{"repo.trash" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "trashRepo")

      assert updated["id"] == to_string(repo.id)
      assert updated["trash"] == true
    end

    test "unauth user trash repo fails", ~m(user_conn guest_conn repo community)a do
      variables = %{id: repo.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoTrashRepo(id: $id, communityId: $communityId) {
        id
        trash
      }
    }
    """
    test "auth user can undo trash repo", ~m(community repo)a do
      variables = %{id: repo.id, communityId: community.id}

      {:ok, _} = CMS.set_community_flags(repo, community.id, %{trash: true})

      passport_rules = %{community.raw => %{"repo.undo_trash" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoTrashRepo")

      assert updated["id"] == to_string(repo.id)
      assert updated["trash"] == false
    end

    test "unauth user undo trash repo fails", ~m(user_conn guest_conn community repo)a do
      variables = %{id: repo.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinRepo(id: $id, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can pin repo", ~m(community repo)a do
      variables = %{id: repo.id, communityId: community.id}

      passport_rules = %{community.raw => %{"repo.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinRepo")

      assert updated["id"] == to_string(repo.id)
    end

    test "unauth user pin repo fails", ~m(user_conn guest_conn community repo)a do
      variables = %{id: repo.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinRepo(id: $id, communityId: $communityId) {
        id
        pin
      }
    }
    """
    test "auth user can undo pin repo", ~m(community repo)a do
      variables = %{id: repo.id, communityId: community.id}

      passport_rules = %{community.raw => %{"repo.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_content(repo, community)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinRepo")

      assert updated["id"] == to_string(repo.id)
    end

    test "unauth user undo pin repo fails", ~m(user_conn guest_conn community repo)a do
      variables = %{id: repo.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
