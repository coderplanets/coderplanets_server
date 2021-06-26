defmodule GroupherServer.Test.Mutation.AbuseReports.RadarReport do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    radar_attrs = mock_attrs(:radar, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community radar_attrs)a}
  end

  describe "[radar report/undo_report]" do
    @report_query """
    mutation($id: ID!, $reason: String!, $attr: String) {
      reportRadar(id: $id, reason: $reason, attr: $attr) {
        id
        title
      }
    }
    """

    test "login user can report a radar", ~m(community radar_attrs user user_conn)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      variables = %{id: radar.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportRadar")

      assert article["id"] == to_string(radar.id)
    end

    @undo_report_query """
    mutation($id: ID!) {
      undoReportRadar(id: $id) {
        id
        title
      }
    }
    """

    test "login user can undo report a radar", ~m(community radar_attrs user user_conn)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      variables = %{id: radar.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportRadar")

      assert article["id"] == to_string(radar.id)

      variables = %{id: radar.id}

      article = user_conn |> mutation_result(@undo_report_query, variables, "undoReportRadar")

      assert article["id"] == to_string(radar.id)
    end
  end
end
