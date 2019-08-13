defmodule GroupherServer.Test.Mutation.JobFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, job} = CMS.create_content(community, :job, mock_attrs(:job), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community job)a}
  end

  describe "[mutation job flag curd]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      trashJob(id: $id, communityId: $communityId) {
        id
        trash
      }
    }
    """
    test "auth user can trash job", ~m(community job)a do
      variables = %{id: job.id, communityId: community.id}

      passport_rules = %{community.raw => %{"job.trash" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "trashJob")

      assert updated["id"] == to_string(job.id)
      assert updated["trash"] == true
    end

    test "unauth user trash job fails", ~m(user_conn guest_conn job community)a do
      variables = %{id: job.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoTrashJob(id: $id, communityId: $communityId) {
        id
        trash
      }
    }
    """
    test "auth user can undo trash job", ~m(community job)a do
      variables = %{id: job.id, communityId: community.id}

      {:ok, _} = CMS.set_community_flags(community, job, %{trash: true})

      passport_rules = %{community.raw => %{"job.undo_trash" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoTrashJob")

      assert updated["id"] == to_string(job.id)
      assert updated["trash"] == false
    end

    test "unauth user undo trash job fails", ~m(user_conn guest_conn community job)a do
      variables = %{id: job.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinJob(id: $id, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can pin job", ~m(community job)a do
      variables = %{id: job.id, communityId: community.id}

      passport_rules = %{community.raw => %{"job.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinJob")

      assert updated["id"] == to_string(job.id)
    end

    test "unauth user pin job fails", ~m(user_conn guest_conn community job)a do
      variables = %{id: job.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinJob(id: $id, communityId: $communityId) {
        id
        pin
      }
    }
    """
    test "auth user can undo pin job", ~m(community job)a do
      variables = %{id: job.id, communityId: community.id}

      passport_rules = %{community.raw => %{"job.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_content(job, community)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinJob")

      assert updated["id"] == to_string(job.id)
      # assert updated["pin"] == false
    end

    test "unauth user undo pin job fails", ~m(user_conn guest_conn community job)a do
      variables = %{id: job.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
