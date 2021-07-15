defmodule GroupherServer.Billing.Delegate.CURD do
  @moduledoc """
  create update & list for billings
  """
  import Ecto.Query, warn: false
  import Helper.Utils
  import Helper.ErrorCode
  import ShortMaps

  alias Helper.ORM

  alias GroupherServer.{Accounts, Billing}
  alias Accounts.Model.User
  alias Billing.Model.BillRecord
  alias Billing.Delegate.Actions
  alias GroupherServer.Repo
  alias GroupherServer.Email

  alias Ecto.Multi

  @doc """
  list all the bill records
  """
  def paged_records(%User{id: user_id}, %{page: page, size: size} = _filter) do
    with {:ok, user} <- ORM.find(User, user_id) do
      BillRecord
      |> where([r], r.user_id == ^user.id)
      |> ORM.paginator(page: page, size: size)
      |> done()
    end
  end

  @doc """
  create bill recoard with pending state
  """
  def create_record(%User{id: user_id}, attrs) do
    with {:ok, user} <- ORM.find(User, user_id) do
      case ORM.find_by(BillRecord, user_id: user.id, state: "pending") do
        {:ok, _record} ->
          {:error, [message: "you have pending bill", code: ecode(:exsit_pending_bill)]}

        {:error, _} ->
          do_create_record(user, attrs)
      end
    end
  end

  @doc """
  update the bill state to: done/reject
  """
  def update_record_state(record_id, state) do
    Multi.new()
    |> Multi.run(:update_state, fn _, _ ->
      do_update_record_state(record_id, state)
    end)
    |> Multi.run(:after_action, fn _, %{update_state: record} ->
      Actions.after_bill(record, state)
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

  defp do_update_record_state(record_id, state) do
    state = to_string(state)

    with {:ok, bill_record} <- ORM.find(BillRecord, record_id) do
      bill_record
      |> Ecto.Changeset.change(~m(state)a)
      |> BillRecord.state_changeset(~m(state)a)
      |> Repo.update()
    end
  end

  defp do_create_record(%User{id: user_id}, attrs) do
    hash_id = Nanoid.generate(8)
    state = "pending"

    attrs =
      attrs
      |> Map.merge(~m(user_id hash_id state)a)
      |> map_atom_value(:string)

    with {:ok, record} <- ORM.create(BillRecord, attrs) do
      Email.notify_admin(record, :payment)

      {:ok, record}
    end
  end
end
