defmodule GroupherServer.Test.CMS.AbuseReports.CommentReport do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)

    {:ok, ~m(user user2 post job)a}
  end

  describe "[article comment report/unreport]" do
    @tag :wip2
    test "report a comment should have a abuse report record", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, _comment} = CMS.report_article_comment(comment.id, "reason", "attr", user)

      filter = %{content_type: :article_comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.list_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases
      assert report.article_comment.id == comment.id

      assert all_reports.total_count == 1
      assert report.report_cases_count == 1
      assert List.first(report_cases).user.login == user.login
    end

    @tag :wip2
    test "different user report a comment should have same report with different report cases",
         ~m(user user2 post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, _} = CMS.report_article_comment(comment.id, "reason", "attr", user)
      {:ok, _} = CMS.report_article_comment(comment.id, "reason", "attr", user2)

      filter = %{content_type: :article_comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.list_reports(filter)

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
      {:ok, comment} = CMS.report_article_comment(comment.id, "reason", "attr", user)
      assert {:error, _} = CMS.report_article_comment(comment.id, "reason", "attr", user)
    end
  end
end
