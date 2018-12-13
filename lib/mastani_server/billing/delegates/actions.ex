defmodule MastaniServer.Billing.Delegate.Actions do
  @moduledoc """
  actions after biling state success
  """
  import Helper.Utils, only: [get_config: 2]

  alias MastaniServer.Accounts
  alias MastaniServer.Billing.BillRecord

  alias Accounts.User

  @senior_amount_threshold get_config(:general, :senior_amount_threshold)

  def after_bill(%BillRecord{payment_usage: "donate", amount: amount} = record, :done) do
    plan = if amount >= @senior_amount_threshold, do: :senior, else: :donate

    with {:ok, _} <- Accounts.upgrade_by_plan(%User{id: record.user_id}, plan) do
      {:ok, record}
    end
  end

  def after_bill(%BillRecord{payment_usage: "senior"} = record, :done) do
    with {:ok, _} <- Accounts.upgrade_by_plan(%User{id: record.user_id}, :senior) do
      {:ok, record}
    end
  end

  def after_bill(%BillRecord{payment_usage: "girls_code_too_plan"} = record, :done) do
    with {:ok, _} <- Accounts.upgrade_by_plan(%User{id: record.user_id}, :senior) do
      {:ok, record}
    end
  end

  def after_bill(%BillRecord{payment_usage: "sponsor"} = record, :done) do
    with {:ok, _} <- Accounts.upgrade_by_plan(%User{id: record.user_id}, :sponsor) do
      {:ok, record}
    end
  end

  def after_bill(%BillRecord{payment_usage: _payment_usage}, _state) do
    {:error, "mismatch action"}
  end
end
