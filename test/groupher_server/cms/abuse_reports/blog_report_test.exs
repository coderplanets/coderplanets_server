defmodule GroupherServer.Test.CMS.AbuseReports.BlogReport do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Blog

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    {:ok, community} = db_insert(:community)
    blog_attrs = mock_attrs(:blog, %{community_id: community.id})

    {:ok, ~m(user user2 community blog_attrs)a}
  end

  describe "[article blog report/unreport]" do
    test "list article reports should work", ~m(community user user2 blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, _report} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user2)

      filter = %{content_type: :blog, content_id: blog.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = all_reports.entries |> List.first()
      assert report.article.id == blog.id
      assert report.article.thread == "BLOG"
    end

    test "report a blog should have a abuse report record", ~m(community user blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, _report} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user)

      filter = %{content_type: :blog, content_id: blog.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert report.article.id == blog.id
      assert all_reports.total_count == 1
      assert report.report_cases_count == 1
      assert List.first(report_cases).user.login == user.login

      {:ok, blog} = ORM.find(Blog, blog.id)
      assert blog.meta.reported_count == 1
      assert user.id in blog.meta.reported_user_ids
    end

    test "can undo a report", ~m(community user blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, _report} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.undo_report_article(:blog, blog.id, user)

      filter = %{content_type: :blog, content_id: blog.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 0

      {:ok, blog} = ORM.find(Blog, blog.id)
      assert user.id not in blog.meta.reported_user_ids
    end

    test "can undo a existed report", ~m(community user user2 blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, _report} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user2)
      {:ok, _report} = CMS.undo_report_article(:blog, blog.id, user)

      filter = %{content_type: :blog, content_id: blog.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      {:ok, blog} = ORM.find(Blog, blog.id)

      assert user2.id in blog.meta.reported_user_ids
      assert user.id not in blog.meta.reported_user_ids
    end

    test "can undo a report with other user report it too",
         ~m(community user user2 blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, _report} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user2)

      filter = %{content_type: :blog, content_id: blog.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 2
      assert Enum.any?(report.report_cases, &(&1.user.login == user.login))
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))

      {:ok, _report} = CMS.undo_report_article(:blog, blog.id, user)

      filter = %{content_type: :blog, content_id: blog.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 1
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))
    end

    test "different user report a comment should have same report with different report cases",
         ~m(community user user2 blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, _report} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:blog, blog.id, "reason2", "attr_info 2", user2)

      filter = %{content_type: :blog, content_id: blog.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert all_reports.total_count == 1
      assert length(report_cases) == 2
      assert report.report_cases_count == 2

      assert List.first(report_cases).user.login == user.login
      assert List.last(report_cases).user.login == user2.login
    end

    test "same user can not report a comment twice", ~m(community blog_attrs user)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, _report} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user)
      assert {:error, _report} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user)
    end
  end
end
