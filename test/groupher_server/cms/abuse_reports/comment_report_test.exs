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
    test "report a comment should have a abuse report record", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)

      filter = %{content_type: :comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases
      assert report.comment.id == comment.id

      assert all_reports.total_count == 1
      assert report.report_cases_count == 1
      assert List.first(report_cases).user.login == user.login
    end

    test "different user report a comment should have same report with different report cases",
         ~m(user user2 post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
      {:ok, _} = CMS.report_comment(comment.id, mock_comment(), "attr", user2)

      filter = %{content_type: :comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert all_reports.total_count == 1
      assert length(report_cases) == 2
      assert report.report_cases_count == 2

      assert List.first(report_cases).user.login == user.login
      assert List.last(report_cases).user.login == user2.login
    end

    test "same user can not report a comment twice", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
      assert {:error, _} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
    end
  end
end
