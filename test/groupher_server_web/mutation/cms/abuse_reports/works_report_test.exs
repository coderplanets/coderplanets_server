defmodule GroupherServer.Test.Mutation.AbuseReports.WorksReport do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    works_attrs = mock_attrs(:works, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community works_attrs)a}
  end

  describe "[works report/undo_report]" do
    @report_query """
    mutation($id: ID!, $reason: String!, $attr: String) {
      reportWorks(id: $id, reason: $reason, attr: $attr) {
        id
        title
      }
    }
    """

    test "login user can report a works", ~m(community works_attrs user user_conn)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      variables = %{id: works.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportWorks")

      assert article["id"] == to_string(works.id)
    end

    @undo_report_query """
    mutation($id: ID!) {
      undoReportWorks(id: $id) {
        id
        title
      }
    }
    """

    test "login user can undo report a works", ~m(community works_attrs user user_conn)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      variables = %{id: works.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportWorks")

      assert article["id"] == to_string(works.id)

      variables = %{id: works.id}

      article = user_conn |> mutation_result(@undo_report_query, variables, "undoReportWorks")

      assert article["id"] == to_string(works.id)
    end
  end
end
