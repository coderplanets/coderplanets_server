defmodule GroupherServer.Test.Billing do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.Accounts.Model.User
  alias GroupherServer.Billing

  @senior_amount_threshold get_config(:general, :senior_amount_threshold)

  setup do
    {:ok, user} = db_insert(:user)

    valid_attrs = mock_attrs(:bill)

    {:ok, ~m(user valid_attrs)a}
  end

  describe "[billing curd]" do
    test "create bill record with valid attrs", ~m(user valid_attrs)a do
      {:ok, record} = Billing.create_record(user, valid_attrs)

      assert record.amount == @senior_amount_threshold
      assert record.payment_usage == "donate"
      assert record.state == "pending"
      assert record.user_id == user.id
      assert String.length(record.hash_id) == 8
    end

    test "create bill record with valid note", ~m(user valid_attrs)a do
      {:ok, record} = Billing.create_record(user, valid_attrs |> Map.merge(%{note: "i am girl"}))

      assert record.note == "i am girl"
    end

    test "create bill record with previous record unhandled fails", ~m(user valid_attrs)a do
      {:ok, _record} = Billing.create_record(user, valid_attrs)
      {:error, reason} = Billing.create_record(user, valid_attrs)
      assert reason |> Keyword.get(:code) == ecode(:exsit_pending_bill)
    end

    test "record state can be update", ~m(user valid_attrs)a do
      {:ok, record} = Billing.create_record(user, valid_attrs)

      {:ok, updated} = Billing.update_record_state(record.id, :done)
      assert updated.state == "done"
    end

    test "can get paged bill records of a user", ~m(user valid_attrs)a do
      {:ok, _record} = Billing.create_record(user, valid_attrs)

      {:ok, records} = Billing.paged_records(user, %{page: 1, size: 20})

      records |> is_valid_pagination?(:raw)
      assert records.entries |> List.first() |> Map.get(:user_id) == user.id
    end
  end

  describe "[after billing]" do
    test "user updgrade to senior_member after senior bill handled", ~m(user valid_attrs)a do
      attrs = valid_attrs |> Map.merge(%{amount: @senior_amount_threshold})

      {:ok, record} = Billing.create_record(user, attrs)
      {:ok, _updated} = Billing.update_record_state(record.id, :done)

      {:ok, %{achievement: achievement}} = ORM.find(User, user.id, preload: :achievement)
      assert achievement.senior_member == true
    end

    test "user updgrade to donate_member after donate bill handled", ~m(user valid_attrs)a do
      attrs = valid_attrs |> Map.merge(%{amount: @senior_amount_threshold - 10})

      {:ok, record} = Billing.create_record(user, attrs)
      {:ok, _updated} = Billing.update_record_state(record.id, :done)

      {:ok, %{achievement: achievement}} = ORM.find(User, user.id, preload: :achievement)
      assert achievement.donate_member == true
    end

    test "girls updgrade to senior_member after bill handled", ~m(user valid_attrs)a do
      attrs = valid_attrs |> Map.merge(%{amount: 0, payment_usage: "girls_code_too_plan"})

      {:ok, record} = Billing.create_record(user, attrs)
      {:ok, _updated} = Billing.update_record_state(record.id, :done)

      {:ok, %{achievement: achievement}} = ORM.find(User, user.id, preload: :achievement)
      assert achievement.senior_member == true
    end

    test "sponsor updgrade to senior_member after bill handled", ~m(user valid_attrs)a do
      attrs = valid_attrs |> Map.merge(%{amount: 0, payment_usage: "sponsor"})

      {:ok, record} = Billing.create_record(user, attrs)
      {:ok, _updated} = Billing.update_record_state(record.id, :done)

      {:ok, %{achievement: achievement}} = ORM.find(User, user.id, preload: :achievement)
      assert achievement.sponsor_member == true
    end
  end
end
