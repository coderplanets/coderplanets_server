defmodule GroupherServer.Test.Mutation.AbuseReports.JobReport do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    job_attrs = mock_attrs(:job, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community job_attrs)a}
  end

  describe "[job report/undo_report]" do
    @report_query """
    mutation($id: ID!, $reason: String!, $attr: String) {
      reportJob(id: $id, reason: $reason, attr: $attr) {
        id
        title
      }
    }
    """

    test "login user can report a job", ~m(community job_attrs user user_conn)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      variables = %{id: job.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportJob")

      assert article["id"] == to_string(job.id)
    end

    @undo_report_query """
    mutation($id: ID!) {
      undoReportJob(id: $id) {
        id
        title
      }
    }
    """

    test "login user can undo report a job", ~m(community job_attrs user user_conn)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      variables = %{id: job.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportJob")

      assert article["id"] == to_string(job.id)

      variables = %{id: job.id}

      article = user_conn |> mutation_result(@undo_report_query, variables, "undoReportJob")

      assert article["id"] == to_string(job.id)
    end
  end
end
