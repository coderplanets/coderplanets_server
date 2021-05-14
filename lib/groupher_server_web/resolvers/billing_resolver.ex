defmodule GroupherServerWeb.Resolvers.Billing do
  @moduledoc """
  accounts resolvers
  """

  # import ShortMaps
  # import Helper.ErrorCode

  alias GroupherServer.Billing

  def paged_bill_records(_root, %{filter: filter}, %{context: %{cur_user: cur_user}}) do
    Billing.paged_records(cur_user, filter)
  end

  def create_bill(_root, args, %{context: %{cur_user: cur_user}}) do
    Billing.create_record(cur_user, args)
  end

  def update_bill_state(_root, %{id: id, state: state}, %{context: %{cur_user: _cur_user}}) do
    Billing.update_record_state(id, state)
  end
end
