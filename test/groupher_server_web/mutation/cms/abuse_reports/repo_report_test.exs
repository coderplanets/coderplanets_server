defmodule GroupherServer.Test.Mutation.AbuseReports.RepoReport do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    repo_attrs = mock_attrs(:repo, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community repo_attrs)a}
  end

  describe "[repo report/undo_report]" do
    @report_query """
    mutation($id: ID!, $reason: String!, $attr: String) {
      reportRepo(id: $id, reason: $reason, attr: $attr) {
        id
        title
      }
    }
    """

    test "login user can report a repo", ~m(community repo_attrs user user_conn)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      variables = %{id: repo.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportRepo")

      assert article["id"] == to_string(repo.id)
    end

    @undo_report_query """
    mutation($id: ID!) {
      undoReportRepo(id: $id) {
        id
        title
      }
    }
    """

    test "login user can undo report a repo", ~m(community repo_attrs user user_conn)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      variables = %{id: repo.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportRepo")

      assert article["id"] == to_string(repo.id)

      variables = %{id: repo.id}

      article = user_conn |> mutation_result(@undo_report_query, variables, "undoReportRepo")

      assert article["id"] == to_string(repo.id)
    end
  end
end
