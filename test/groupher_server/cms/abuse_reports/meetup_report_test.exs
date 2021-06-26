defmodule GroupherServer.Test.CMS.AbuseReports.MeetupReport do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Meetup

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    {:ok, community} = db_insert(:community)
    meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})

    {:ok, ~m(user user2 community meetup_attrs)a}
  end

  describe "[article meetup report/unreport]" do
    test "list article reports should work", ~m(community user user2 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _report} = CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user2)

      filter = %{content_type: :meetup, content_id: meetup.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = all_reports.entries |> List.first()
      assert report.article.id == meetup.id
      assert report.article.thread == "MEETUP"
    end

    test "report a meetup should have a abuse report record", ~m(community user meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _report} = CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user)

      filter = %{content_type: :meetup, content_id: meetup.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert report.article.id == meetup.id
      assert all_reports.total_count == 1
      assert report.report_cases_count == 1
      assert List.first(report_cases).user.login == user.login

      {:ok, meetup} = ORM.find(Meetup, meetup.id)
      assert meetup.meta.reported_count == 1
      assert user.id in meetup.meta.reported_user_ids
    end

    test "can undo a report", ~m(community user meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _report} = CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.undo_report_article(:meetup, meetup.id, user)

      filter = %{content_type: :meetup, content_id: meetup.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 0

      {:ok, meetup} = ORM.find(Meetup, meetup.id)
      assert user.id not in meetup.meta.reported_user_ids
    end

    test "can undo a existed report", ~m(community user user2 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _report} = CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user2)
      {:ok, _report} = CMS.undo_report_article(:meetup, meetup.id, user)

      filter = %{content_type: :meetup, content_id: meetup.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      {:ok, meetup} = ORM.find(Meetup, meetup.id)

      assert user2.id in meetup.meta.reported_user_ids
      assert user.id not in meetup.meta.reported_user_ids
    end

    test "can undo a report with other user report it too",
         ~m(community user user2 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _report} = CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user2)

      filter = %{content_type: :meetup, content_id: meetup.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 2
      assert Enum.any?(report.report_cases, &(&1.user.login == user.login))
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))

      {:ok, _report} = CMS.undo_report_article(:meetup, meetup.id, user)

      filter = %{content_type: :meetup, content_id: meetup.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 1
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))
    end

    test "different user report a comment should have same report with different report cases",
         ~m(community user user2 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      {:ok, _report} = CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user)
      {:ok, _report} = CMS.report_article(:meetup, meetup.id, "reason2", "attr_info 2", user2)

      filter = %{content_type: :meetup, content_id: meetup.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert all_reports.total_count == 1
      assert length(report_cases) == 2
      assert report.report_cases_count == 2

      assert List.first(report_cases).user.login == user.login
      assert List.last(report_cases).user.login == user2.login
    end

    test "same user can not report a comment twice", ~m(community meetup_attrs user)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      {:ok, _report} = CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user)

      assert {:error, _report} =
               CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user)
    end
  end
end
