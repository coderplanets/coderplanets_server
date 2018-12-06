defmodule MastaniServer.Test.Mutation.Billing.Basic do
  use MastaniServer.TestTools

  alias MastaniServer.Billing

  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    valid_attrs = %{
      amount: 10.24,
      payment_usage: "donate",
      payment_method: "alipay"
    }

    {:ok, ~m(user_conn guest_conn user valid_attrs)a}
  end

  describe "[account curd]" do
    @create_query """
    mutation($paymentMethod: String!, $paymentUsage: String!, $amount: Float!) {
      createBill(paymentMethod: $paymentMethod, paymentUsage: $paymentUsage, amount: $amount) {
        id
        state
        amount
        hashId
        paymentUsage
        paymentMethod
      }
    }
    """
    @tag :wip
    test "auth user can create bill", ~m(user user_conn)a do
      variables = %{
        paymentUsage: "donate",
        paymentMethod: "alipay",
        amount: 512
      }

      created = user_conn |> mutation_result(@create_query, variables, "createBill")

      assert created["amount"] == 512
      assert created["state"] == "pending"
    end

    @update_query """
    mutation($id: ID!, $state: BillStateEnum!) {
      updateBillState(id: $id, state: $state) {
        id
        state
      }
    }
    """
    @tag :wip
    test "auth user can update bill state", ~m(user valid_attrs)a do
      {:ok, record} = Billing.create_record(user, valid_attrs)

      variables = %{
        id: record.id,
        state: "DONE"
      }

      passport_rules = %{"system_accountant" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)
      updated = rule_conn |> mutation_result(@update_query, variables, "updateBillState")

      assert updated["id"] == to_string(record.id)
      assert updated["state"] == "done"
    end
  end
end
