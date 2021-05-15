defmodule GroupherServer.Test.Mutation.Flags.JobFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, job} = CMS.create_article(community, :job, mock_attrs(:job), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community job)a}
  end

  describe "[mutation job flag curd]" do
    @query """
    mutation($id: ID!){
      markDeleteJob(id: $id) {
        id
        markDelete
      }
    }
    """

    test "auth user can markDelete job", ~m(job)a do
      variables = %{id: job.id}

      passport_rules = %{"job.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "markDeleteJob")

      assert updated["id"] == to_string(job.id)
      assert updated["markDelete"] == true
    end

    test "unauth user markDelete job fails", ~m(user_conn guest_conn job)a do
      variables = %{id: job.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoMarkDeleteJob(id: $id) {
        id
        markDelete
      }
    }
    """

    test "auth user can undo markDelete job", ~m(job)a do
      variables = %{id: job.id}

      {:ok, _} = CMS.mark_delete_article(:job, job.id)

      passport_rules = %{"job.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoMarkDeleteJob")

      assert updated["id"] == to_string(job.id)
      assert updated["markDelete"] == false
    end

    test "unauth user undo markDelete job fails", ~m(user_conn guest_conn job)a do
      variables = %{id: job.id}
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
        isPinned
      }
    }
    """

    test "auth user can undo pin job", ~m(community job)a do
      variables = %{id: job.id, communityId: community.id}

      passport_rules = %{community.raw => %{"job.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_article(:job, job.id, community.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinJob")

      assert updated["id"] == to_string(job.id)
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
