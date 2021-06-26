defmodule GroupherServer.Test.CMS.AbuseReports.GuideReport do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Guide

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    {:ok, community} = db_insert(:community)
    guide_attrs = mock_attrs(:guide, %{community_id: community.id})

    {:ok, ~m(user user2 community guide_attrs)a}
  end

  describe "[article guide report/unreport]" do
    test "list article reports should work", ~m(community user user2 guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _report} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user2)

      filter = %{content_type: :guide, content_id: guide.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = all_reports.entries |> List.first()
      assert report.article.id == guide.id
      assert report.article.thread == "GUIDE"
    end

    test "report a guide should have a abuse report record", ~m(community user guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _report} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user)

      filter = %{content_type: :guide, content_id: guide.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert report.article.id == guide.id
      assert all_reports.total_count == 1
      assert report.report_cases_count == 1
      assert List.first(report_cases).user.login == user.login

      {:ok, guide} = ORM.find(Guide, guide.id)
      assert guide.meta.reported_count == 1
      assert user.id in guide.meta.reported_user_ids
    end

    test "can undo a report", ~m(community user guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _report} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.undo_report_article(:guide, guide.id, user)

      filter = %{content_type: :guide, content_id: guide.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 0

      {:ok, guide} = ORM.find(Guide, guide.id)
      assert user.id not in guide.meta.reported_user_ids
    end

    test "can undo a existed report", ~m(community user user2 guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _report} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user2)
      {:ok, _report} = CMS.undo_report_article(:guide, guide.id, user)

      filter = %{content_type: :guide, content_id: guide.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      {:ok, guide} = ORM.find(Guide, guide.id)

      assert user2.id in guide.meta.reported_user_ids
      assert user.id not in guide.meta.reported_user_ids
    end

    test "can undo a report with other user report it too",
         ~m(community user user2 guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _report} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user2)

      filter = %{content_type: :guide, content_id: guide.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 2
      assert Enum.any?(report.report_cases, &(&1.user.login == user.login))
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))

      {:ok, _report} = CMS.undo_report_article(:guide, guide.id, user)

      filter = %{content_type: :guide, content_id: guide.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 1
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))
    end

    test "different user report a comment should have same report with different report cases",
         ~m(community user user2 guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      {:ok, _report} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:guide, guide.id, "reason2", "attr_info 2", user2)

      filter = %{content_type: :guide, content_id: guide.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert all_reports.total_count == 1
      assert length(report_cases) == 2
      assert report.report_cases_count == 2

      assert List.first(report_cases).user.login == user.login
      assert List.last(report_cases).user.login == user2.login
    end

    test "same user can not report a comment twice", ~m(community guide_attrs user)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      {:ok, _report} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user)
      assert {:error, _report} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user)
    end
  end
end
