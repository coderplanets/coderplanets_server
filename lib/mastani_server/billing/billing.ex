defmodule MastaniServer.Billing do
  @moduledoc false

  alias MastaniServer.Billing.Delegate.CURD

  defdelegate create_record(user, attrs), to: CURD
  defdelegate list_records(user, filter), to: CURD
  defdelegate update_record_state(record_id, state), to: CURD
end
