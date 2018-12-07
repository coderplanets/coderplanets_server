defmodule MastaniServer.Billing.Delegate.CURD do
  @moduledoc """
  create update & list for billings
  """
  import Ecto.Query, warn: false
  import Helper.Utils
  import Helper.ErrorCode
  import ShortMaps

  alias Helper.ORM
  alias MastaniServer.Accounts.User
  alias MastaniServer.Billing.BillRecord
  alias MastaniServer.Repo
  alias MastaniServer.Billing.Delegate.Actions

  alias Ecto.Multi

  @doc """
  create bill recoard with pending state
  """
  def create_record(%User{id: user_id}, attrs) do
    with {:ok, user} <- ORM.find(User, user_id) do
      case ORM.find_by(BillRecord, user_id: user.id, state: "pending") do
        {:ok, record} ->
          {:error, [message: "you have pending bill", code: ecode(:exsit_pending_bill)]}

        {:error, _} ->
          do_create_record(user, attrs)
      end
    end
  end

  @doc """
  list all the bill records
  """
  def list_records(%User{id: user_id}, %{page: page, size: size} = _filter) do
    with {:ok, user} <- ORM.find(User, user_id) do
      BillRecord
      |> where([r], r.user_id == ^user.id)
      |> ORM.paginater(page: page, size: size)
      |> done()
    end
  end

  @doc """
  update the bill state to: done/reject
  """
  def update_record_state(record_id, state) do
    Multi.new()
    |> Multi.run(:update_state, fn _, _ ->
      up_update_record_state(record_id, state)
    end)
    |> Multi.run(:after_action, fn _, %{update_state: record} ->
      Actions.after_bill_state(record, state)
    end)
    |> Repo.transaction()
    |> update_state_result()
  end

  defp update_state_result({:ok, %{after_action: result}}), do: {:ok, result}

  defp update_state_result({:error, :update_state, _result, _steps}) do
    {:error, [message: "update state error", code: ecode(:bill_state)]}
  end

  defp update_state_result({:error, :after_action, _result, _steps}) do
    {:error, [message: "update state action error", code: ecode(:bill_action)]}
  end

  defp up_update_record_state(record_id, state) do
    state = to_string(state)

    with {:ok, bill_record} <- ORM.find(BillRecord, record_id) do
      bill_record
      |> Ecto.Changeset.change(~m(state)a)
      |> BillRecord.state_changeset(~m(state)a)
      |> Repo.update()
    end
  end

  defp do_create_record(%User{} = user, attrs) do
    attrs = Map.merge(attrs, %{user_id: user.id, hash_id: Nanoid.generate(8), state: "pending"})
    BillRecord |> ORM.create(attrs)
  end
end
