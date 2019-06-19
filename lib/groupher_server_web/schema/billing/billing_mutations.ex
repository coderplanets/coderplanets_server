defmodule GroupherServerWeb.Schema.Billing.Mutations do
  @moduledoc """
  billing mutations
  """
  use Helper.GqlSchemaSuite

  object :billing_mutations do
    @desc "create bill"
    field :create_bill, :bill do
      arg(:payment_method, non_null(:payment_method_enum))
      arg(:payment_usage, non_null(:payment_usage_enum))
      arg(:amount, non_null(:float))
      arg(:note, :string)

      middleware(M.Authorize, :login)
      resolve(&R.Billing.create_bill/3)
    end

    @desc "update user's bill state"
    field :update_bill_state, :bill do
      arg(:id, non_null(:id))
      arg(:state, non_null(:bill_state_enum))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->system_accountant")

      resolve(&R.Billing.update_bill_state/3)
    end
  end
end
