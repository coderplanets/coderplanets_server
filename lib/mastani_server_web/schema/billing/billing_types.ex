defmodule MastaniServerWeb.Schema.Billing.Types do
  use Helper.GqlSchemaSuite

  import MastaniServerWeb.Schema.Utils.Helper
  import Absinthe.Resolution.Helpers

  # alias MastaniServer.Billing
  alias MastaniServerWeb.Schema

  enum :bill_state_enum do
    value(:pending)
    value(:done)
    value(:reject)
  end

  object :bill do
    field(:id, :id)
    field(:state, :string)
    field(:amount, :float)

    field(:hash_id, :string)
    field(:payment_usage, :string)
    field(:payment_method, :string)

    field(:note, :string)
  end

  object :paged_bills do
    field(:entries, list_of(:bill))
    pagination_fields()
  end
end
