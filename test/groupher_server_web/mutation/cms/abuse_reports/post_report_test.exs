defmodule GroupherServer.Test.Mutation.AbuseReports.PostReport do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community post_attrs)a}
  end

  describe "[post report/undo_report]" do
    @report_query """
    mutation($id: ID!, $reason: String!, $attr: String) {
      reportPost(id: $id, reason: $reason, attr: $attr) {
        id
        title
      }
    }
    """

    test "login user can report a post", ~m(community post_attrs user user_conn)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      variables = %{id: post.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportPost")

      assert article["id"] == to_string(post.id)
    end

    @undo_report_query """
    mutation($id: ID!) {
      undoReportPost(id: $id) {
        id
        title
      }
    }
    """

    test "login user can undo report a post", ~m(community post_attrs user user_conn)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      variables = %{id: post.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportPost")

      assert article["id"] == to_string(post.id)

      variables = %{id: post.id}

      article = user_conn |> mutation_result(@undo_report_query, variables, "undoReportPost")
      assert article["id"] == to_string(post.id)
    end
  end
end
