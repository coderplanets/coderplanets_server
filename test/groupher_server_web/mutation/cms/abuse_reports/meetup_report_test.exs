defmodule GroupherServer.Test.Mutation.AbuseReports.MeetupReport do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community meetup_attrs)a}
  end

  describe "[meetup report/undo_report]" do
    @report_query """
    mutation($id: ID!, $reason: String!, $attr: String) {
      reportMeetup(id: $id, reason: $reason, attr: $attr) {
        id
        title
      }
    }
    """

    test "login user can report a meetup", ~m(community meetup_attrs user user_conn)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      variables = %{id: meetup.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportMeetup")

      assert article["id"] == to_string(meetup.id)
    end

    @undo_report_query """
    mutation($id: ID!) {
      undoReportMeetup(id: $id) {
        id
        title
      }
    }
    """

    test "login user can undo report a meetup", ~m(community meetup_attrs user user_conn)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      variables = %{id: meetup.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportMeetup")

      assert article["id"] == to_string(meetup.id)

      variables = %{id: meetup.id}

      article = user_conn |> mutation_result(@undo_report_query, variables, "undoReportMeetup")

      assert article["id"] == to_string(meetup.id)
    end
  end
end
