defmodule MastaniServer.Test.Billing do
  use MastaniServer.TestTools

  alias MastaniServer.Accounts.User
  alias MastaniServer.Billing
  # alias MastaniServer.CMS

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)

    valid_attrs = %{
      amount: 10.24,
      payment_usage: "donate",
      payment_method: "alipay"
    }

    {:ok, ~m(user valid_attrs)a}
  end

  describe "[billing curd]" do
    @tag :wip
    test "create create bill record with valid attrs", ~m(user valid_attrs)a do
      {:ok, record} = Billing.create_record(user, valid_attrs)

      assert record.amount == 10.24
      assert record.payment_usage == "donate"
      assert record.state == "pending"
      assert record.user_id == user.id
      assert String.length(record.hash_id) == 8
    end

    @tag :wip
    test "create bill record with previous record unhandled fails", ~m(user valid_attrs)a do
      {:ok, record} = Billing.create_record(user, valid_attrs)
      {:error, error} = Billing.create_record(user, valid_attrs)
      assert error |> Keyword.get(:code) == ecode(:exsit_pending_bill)
    end

    @tag :wip
    test "can get paged bill records of a user", ~m(user valid_attrs)a do
      {:ok, record} = Billing.create_record(user, valid_attrs)

      {:ok, records} = Billing.get_records(user, %{page: 1, size: 20})

      records |> is_valid_pagination?(:raw)
      assert records.entries |> List.first() |> Map.get(:user_id) == user.id
    end
  end
end
