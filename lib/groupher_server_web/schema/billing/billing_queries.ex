defmodule GroupherServerWeb.Schema.Billing.Queries do
  @moduledoc """
  billing GraphQL queries
  """
  use Helper.GqlSchemaSuite

  object :billing_queries do
    @desc "get all bills"
    field :paged_bill_records, non_null(:paged_bills) do
      arg(:filter, non_null(:paged_filter))

      middleware(M.Authorize, :login)
      middleware(M.PageSizeProof)

      resolve(&R.Billing.paged_bill_records/3)
    end
  end
end
