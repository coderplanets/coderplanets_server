defmodule GroupherServer.Test.Query.AbuseReports.PostReport do
  @moduledoc false

  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  alias GroupherServer.Repo

  alias CMS.Post

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    {:ok, community} = db_insert(:community)
    post_attrs = mock_attrs(:post, %{community_id: community.id})

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community post post_attrs user user2)a}
  end

  describe "[query paged_posts filter pagination]" do
    # id
    @query """
    query($filter: ReportFilter!) {
      pagedAbuseReports(filter: $filter) {
        entries {
          id
          dealWith
          operateUser {
            id
            login
          }
          articleComment {
            id
            bodyHtml
            author {
              login
            }
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    @tag :wip
    test "should get pagination info", ~m(guest_conn community post_attrs user user2)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)
      {:ok, _report} = CMS.report_article(:post, post.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:post, post.id, "reason", "attr_info", user2)

      variables = %{filter: %{content_type: "POST", page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedAbuseReports")

      assert results |> is_valid_pagination?
    end

    @tag :wip2
    test "support article_comment", ~m(guest_conn post user)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "comment", user)
      {:ok, _} = CMS.report_article_comment(comment.id, "reason", "attr", user)

      variables = %{filter: %{content_type: "ARTICLE_COMMENT", page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedAbuseReports")

      IO.inspect(results, label: "results- -")

      report = results["entries"] |> List.first()
      assert get_in(report, ["articleComment", "bodyHtml"]) == "comment"
      assert get_in(report, ["articleComment", "id"]) == to_string(comment.id)
      assert not is_nil(get_in(report, ["articleComment", "author", "login"]))
    end
  end
end
