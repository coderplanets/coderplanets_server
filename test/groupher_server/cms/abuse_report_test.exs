defmodule GroupherServer.Test.CMS.AbuseReport do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.AbuseReport

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)

    {:ok, ~m(user user2 post job)a}
  end

  describe "[article comment report/unreport]" do
    @tag :wip
    test "report a comment should have a abuse report record", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, _comment} = CMS.report_article_comment(comment.id, user)

      {:ok, all_reports} = ORM.find_all(AbuseReport, %{page: 1, size: 10})
      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert all_reports.total_count == 1
      assert report.report_cases_count == 1
      assert List.first(report_cases).user.login == user.login
    end

    @tag :wip
    test "different user report a comment should have same report with different report cases",
         ~m(user user2 post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, _} = CMS.report_article_comment(comment.id, user)
      {:ok, _} = CMS.report_article_comment(comment.id, user2)

      {:ok, all_reports} = ORM.find_all(AbuseReport, %{page: 1, size: 10})

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