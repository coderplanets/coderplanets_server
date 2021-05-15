defmodule GroupherServer.Test.Mutation.Flags.RepoFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, repo} = CMS.create_article(community, :repo, mock_attrs(:repo), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community repo)a}
  end

  describe "[mutation repo flag curd]" do
    @query """
    mutation($id: ID!){
      markDeleteRepo(id: $id) {
        id
        markDelete
      }
    }
    """

    test "auth user can markDelete repo", ~m(repo)a do
      variables = %{id: repo.id}

      passport_rules = %{"repo.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "markDeleteRepo")

      assert updated["id"] == to_string(repo.id)
      assert updated["markDelete"] == true
    end

    test "unauth user markDelete repo fails", ~m(user_conn guest_conn repo)a do
      variables = %{id: repo.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoMarkDeleteRepo(id: $id) {
        id
        markDelete
      }
    }
    """

    test "auth user can undo markDelete repo", ~m(repo)a do
      variables = %{id: repo.id}

      {:ok, _} = CMS.mark_delete_article(:repo, repo.id)

      passport_rules = %{"repo.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoMarkDeleteRepo")

      assert updated["id"] == to_string(repo.id)
      assert updated["markDelete"] == false
    end

    test "unauth user undo markDelete repo fails", ~m(user_conn guest_conn repo)a do
      variables = %{id: repo.id}
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
        isPinned
      }
    }
    """

    test "auth user can undo pin repo", ~m(community repo)a do
      variables = %{id: repo.id, communityId: community.id}

      passport_rules = %{community.raw => %{"repo.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_article(:repo, repo.id, community.id)
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
