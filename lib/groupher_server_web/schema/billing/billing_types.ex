defmodule GroupherServerWeb.Schema.Billing.Types do
  @moduledoc """
  general types used by Billing
  """
  use Helper.GqlSchemaSuite

  import GroupherServerWeb.Schema.Helper.Fields

  enum :bill_state_enum do
    value(:pending)
    value(:done)
    value(:reject)
  end

  enum :payment_usage_enum do
    value(:senior)
    value(:girls_code_too_plan)
    value(:donate)
    value(:sponsor)
    # cms
    # value(:pin_post) #...
  end

  enum :payment_method_enum do
    value(:wechat)
    value(:alipay)
  end

  object :bill do
    field(:id, :id)
    field(:state, :string)
    field(:amount, :float)

    field(:hash_id, :string)
    field(:payment_usage, :string)
    field(:payment_method, :string)

    field(:note, :string)
    field(:inserted_at, :datetime)
  end

  object :paged_bills do
    field(:entries, list_of(:bill))
    pagination_fields()
  end
end
