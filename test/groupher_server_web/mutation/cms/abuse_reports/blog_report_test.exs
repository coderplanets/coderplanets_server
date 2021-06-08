defmodule GroupherServer.Test.Mutation.AbuseReports.BlogReport do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    blog_attrs = mock_attrs(:blog, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community blog_attrs)a}
  end

  describe "[blog report/undo_report]" do
    @report_query """
    mutation($id: ID!, $reason: String!, $attr: String) {
      reportBlog(id: $id, reason: $reason, attr: $attr) {
        id
        title
      }
    }
    """

    test "login user can report a blog", ~m(community blog_attrs user user_conn)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      variables = %{id: blog.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportBlog")

      assert article["id"] == to_string(blog.id)
    end

    @undo_report_query """
    mutation($id: ID!) {
      undoReportBlog(id: $id) {
        id
        title
      }
    }
    """

    test "login user can undo report a blog", ~m(community blog_attrs user user_conn)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      variables = %{id: blog.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportBlog")

      assert article["id"] == to_string(blog.id)

      variables = %{id: blog.id}

      article = user_conn |> mutation_result(@undo_report_query, variables, "undoReportBlog")

      assert article["id"] == to_string(blog.id)
    end
  end
end
