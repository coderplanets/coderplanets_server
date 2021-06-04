# report_account

defmodule GroupherServer.Test.CMS.AbuseReports.AccountReport do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias GroupherServer.Accounts

  alias Accounts.Model.User

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)

    {:ok, community} = db_insert(:community)
    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community post_attrs)a}
  end

  describe "[account report/unreport]" do
    # test "list article reports should work", ~m(community user user2 post_attrs)a do
    #   {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
    #   {:ok, _report} = CMS.report_article(:post, post.id, "reason", "attr_info", user)
    #   {:ok, _report} = CMS.report_article(:post, post.id, "reason", "attr_info", user2)

    #   filter = %{content_type: :post, content_id: post.id, page: 1, size: 20}
    #   {:ok, all_reports} = CMS.paged_reports(filter)

    #   report = all_reports.entries |> List.first()
    #   assert report.article.id == post.id
    #   assert report.article.thread == :post
    # end

    test "report an account should have a abuse report record", ~m(user user2)a do
      {:ok, _report} = CMS.report_account(user.id, "reason", "attr_info", user2)

      filter = %{content_type: :account, content_id: user.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert report.account.id == user.id
      assert all_reports.total_count == 1
      assert report.report_cases_count == 1
      assert List.first(report_cases).user.login == user2.login

      {:ok, user} = ORM.find(User, user.id)
      assert user.meta.reported_count == 1
    end

    test "can undo a report", ~m(user user2)a do
      {:ok, _report} = CMS.report_account(user.id, "reason", "attr_info", user2)
      {:ok, user} = ORM.find(User, user.id)
      assert user2.id in user.meta.reported_user_ids

      {:ok, _report} = CMS.undo_report_account(user.id, user2)

      filter = %{content_type: :account, content_id: user.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 0

      {:ok, user} = ORM.find(User, user.id)
      assert user2.id not in user.meta.reported_user_ids
    end

    test "can undo a existed report", ~m(user user2 user3)a do
      {:ok, _report} = CMS.report_account(user.id, "reason", "attr_info", user2)
      {:ok, _report} = CMS.report_account(user.id, "reason", "attr_info", user3)
      {:ok, _report} = CMS.undo_report_account(user.id, user2)

      filter = %{content_type: :account, content_id: user.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      {:ok, user} = ORM.find(User, user.id)
      assert user2.id not in user.meta.reported_user_ids
      assert user3.id in user.meta.reported_user_ids
    end

    test "can undo a report with other user report it too", ~m(user user2 user3)a do
      {:ok, _report} = CMS.report_account(user.id, "reason", "attr_info", user2)
      {:ok, _report} = CMS.report_account(user.id, "reason", "attr_info", user3)

      filter = %{content_type: :account, content_id: user.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 2
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))
      assert Enum.any?(report.report_cases, &(&1.user.login == user3.login))

      {:ok, _report} = CMS.undo_report_account(user.id, user2)

      filter = %{content_type: :account, content_id: user.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 1
      assert Enum.any?(report.report_cases, &(&1.user.login == user3.login))
    end

    test "different user report a account should have same report with different report cases",
         ~m(user user2 user3)a do
      {:ok, _report} = CMS.report_account(user.id, "reason", "attr_info", user2)
      {:ok, _report} = CMS.report_account(user.id, "reason", "attr_info", user3)

      filter = %{content_type: :account, content_id: user.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      report = List.first(all_reports.entries)
      report_cases = report.report_cases

      assert all_reports.total_count == 1
      assert length(report_cases) == 2
      assert report.report_cases_count == 2

      assert List.first(report_cases).user.login == user2.login
      assert List.last(report_cases).user.login == user3.login
    end

    test "same user can not report a account twice", ~m(user user2)a do
      {:ok, _report} = CMS.report_account(user.id, "reason", "attr_info", user2)
      assert {:error, _report} = CMS.report_account(user.id, "reason", "attr_info", user2)
    end
  end
end
