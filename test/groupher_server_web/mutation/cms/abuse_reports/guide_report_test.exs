defmodule GroupherServer.Test.Mutation.AbuseReports.GuideReport do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guide_attrs = mock_attrs(:guide, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community guide_attrs)a}
  end

  describe "[guide report/undo_report]" do
    @report_query """
    mutation($id: ID!, $reason: String!, $attr: String) {
      reportGuide(id: $id, reason: $reason, attr: $attr) {
        id
        title
      }
    }
    """

    test "login user can report a guide", ~m(community guide_attrs user user_conn)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      variables = %{id: guide.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportGuide")

      assert article["id"] == to_string(guide.id)
    end

    @undo_report_query """
    mutation($id: ID!) {
      undoReportGuide(id: $id) {
        id
        title
      }
    }
    """

    test "login user can undo report a guide", ~m(community guide_attrs user user_conn)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      variables = %{id: guide.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportGuide")

      assert article["id"] == to_string(guide.id)

      variables = %{id: guide.id}

      article = user_conn |> mutation_result(@undo_report_query, variables, "undoReportGuide")

      assert article["id"] == to_string(guide.id)
    end
  end
end
