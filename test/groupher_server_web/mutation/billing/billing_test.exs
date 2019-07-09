defmodule GroupherServer.Test.Mutation.Billing.Basic do
  use GroupherServer.TestTools

  import Helper.Utils

  alias GroupherServer.Billing

  @senior_amount_threshold get_config(:general, :senior_amount_threshold)

  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    valid_attrs = mock_attrs(:bill)

    {:ok, ~m(user_conn guest_conn user valid_attrs)a}
  end

  describe "[billing curd]" do
    @create_query """
    mutation(
      $paymentMethod: PaymentMethodEnum!
      $paymentUsage: PaymentUsageEnum!
      $amount: Float!
      $note: String
    ) {
      createBill(
        paymentMethod: $paymentMethod
        paymentUsage: $paymentUsage
        amount: $amount
        note: $note
      ) {
        id
        state
        amount
        hashId
        paymentUsage
        paymentMethod
        note
      }
    }
    """
    test "auth user can create bill", ~m(user_conn valid_attrs)a do
      variables = valid_attrs |> camelize_map_key(:upcase)
      created = user_conn |> mutation_result(@create_query, variables, "createBill")

      assert created["amount"] == @senior_amount_threshold
      assert created["state"] == "pending"
      assert created["note"] !== nil
    end

    @update_query """
    mutation($id: ID!, $state: BillStateEnum!) {
      updateBillState(id: $id, state: $state) {
        id
        state
      }
    }
    """
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
