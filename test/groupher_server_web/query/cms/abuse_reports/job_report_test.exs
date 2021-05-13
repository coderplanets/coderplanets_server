defmodule GroupherServer.Test.Query.AbuseReports.JobReport do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    {:ok, community} = db_insert(:community)
    job_attrs = mock_attrs(:job, %{community_id: community.id})

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community job job_attrs user user2)a}
  end

  describe "[query paged_jobs filter pagination]" do
    # id
    @query """
    query($filter: ReportFilter!) {
      pagedAbuseReports(filter: $filter) {
        entries {
          id
          dealWith
          article {
            id
            thread
            title
          }
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
          reportCases {
            reason
            attr
            user {
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
    @tag :wip2
    test "should get pagination info", ~m(guest_conn community job_attrs user user2)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)
      {:ok, job2} = CMS.create_content(community, :job, job_attrs, user)

      {:ok, _report} = CMS.report_article(:job, job.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:job, job2.id, "reason", "attr_info", user2)

      variables = %{filter: %{content_type: "JOB", page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedAbuseReports")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 2
    end

    @tag :wip2
    test "support search with id", ~m(guest_conn user user2)a do
      {:ok, job} = db_insert(:job)
      {:ok, job2} = db_insert(:job)

      {:ok, _report} = CMS.report_article(:job, job.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:job, job2.id, "reason", "attr_info", user2)

      variables = %{filter: %{content_type: "JOB", content_id: job.id, page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedAbuseReports")

      report = results["entries"] |> List.first()

      assert get_in(report, ["article", "thread"]) == "JOB"
      assert get_in(report, ["article", "id"]) == to_string(job.id)

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 1
    end

    @tag :wip3
    test "support article_comment", ~m(guest_conn job user)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "comment", user)
      {:ok, _} = CMS.report_article_comment(comment.id, "reason", "attr", user)

      variables = %{filter: %{content_type: "ARTICLE_COMMENT", page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedAbuseReports")

      report = results["entries"] |> List.first()
      report_case = get_in(report, ["reportCases"])
      assert is_list(report_case)

      assert get_in(report, ["articleComment", "bodyHtml"]) == "comment"
      assert get_in(report, ["articleComment", "id"]) == to_string(comment.id)
      assert not is_nil(get_in(report, ["articleComment", "author", "login"]))
    end
  end
end
