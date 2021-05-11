defmodule GroupherServer.Test.CMS.AbuseReports.PostReport do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.AbuseReport

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)

    {:ok, community} = db_insert(:community)
    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 community post_attrs)a}
  end

  describe "[article post report/unreport]" do
    @tag :wip2
    test "report a post should have a abuse report record", ~m(community user post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)
      {:ok, report} = CMS.report_article(:post, post.id, "reason", "attr_info", user)

      {:ok, all_reports} = CMS.list_reports(:post, post.id, %{page: 1, size: 20})

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert report.post_id == post.id
      assert all_reports.total_count == 1
      assert report.report_cases_count == 1
      assert List.first(report_cases).user.login == user.login

      {:ok, post} = ORM.find(CMS.Post, post.id)
      assert post.is_reported
      assert post.meta.reported_count == 1
    end

    @tag :wip
    test "different user report a comment should have same report with different report cases",
         ~m(user user2 post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, _} = CMS.report_article_comment(comment.id, user)
      {:ok, _} = CMS.report_article_comment(comment.id, user2)

      {:ok, all_reports} = CMS.list_reports(:article_comment, comment.id, %{page: 1, size: 20})

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert all_reports.total_count == 1
      assert length(report_cases) == 2
      assert report.report_cases_count == 2

      assert List.first(report_cases).user.login == user.login
      assert List.last(report_cases).user.login == user2.login
    end

    @tag :wip
    test "same user can not report a comment twice", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, comment} = CMS.report_article_comment(comment.id, user)
      assert {:error, _} = CMS.report_article_comment(comment.id, user)
    end
  end
end
