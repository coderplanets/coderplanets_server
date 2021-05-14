defmodule GroupherServer.Billing do
  @moduledoc false

  alias GroupherServer.Billing.Delegate.CURD

  defdelegate create_record(user, attrs), to: CURD
  defdelegate paged_records(user, filter), to: CURD
  defdelegate update_record_state(record_id, state), to: CURD
end
