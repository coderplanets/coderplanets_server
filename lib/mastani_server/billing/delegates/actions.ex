defmodule MastaniServer.Billing.Delegate.Actions do
  @moduledoc """
  actions after biling state success
  """
  alias MastaniServer.Billing.BillRecord

  def after_bill_state(%BillRecord{payment_usage: payment_usage} = record, :done) do
    IO.inspect(payment_usage, label: "do action done")
    {:ok, record}
  end

  def after_bill_state(%BillRecord{} = record, _state) do
    {:ok, record}
  end
end
