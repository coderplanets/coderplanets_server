defmodule GroupherServer.Test.Mutation.Sink.JobSink do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Job

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, job} = CMS.create_article(community, :job, mock_attrs(:job), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn community job user)a}
  end

  describe "[job sink]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      sinkJob(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can sink a job", ~m(community job)a do
      variables = %{id: job.id, communityId: community.id}
      passport_rules = %{community.raw => %{"job.sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "sinkJob")
      assert result["id"] == to_string(job.id)

      {:ok, job} = ORM.find(Job, job.id)
      assert job.meta.is_sinked
      assert job.active_at == job.inserted_at
    end

    test "unauth user sink a job fails", ~m(guest_conn community job)a do
      variables = %{id: job.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoSinkJob(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can undo sink to a job", ~m(community job)a do
      variables = %{id: job.id, communityId: community.id}

      passport_rules = %{community.raw => %{"job.undo_sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, _} = CMS.sink_article(:job, job.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoSinkJob")
      assert updated["id"] == to_string(job.id)

      {:ok, job} = ORM.find(Job, job.id)
      assert not job.meta.is_sinked
    end

    test "unauth user undo sink a job fails", ~m(guest_conn community job)a do
      variables = %{id: job.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
