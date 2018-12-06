defmodule MastaniServer.Billing do
  @moduledoc """
  CURD for all the finacial records
  """
  import Ecto.Query, warn: false
  import Helper.Utils
  import Helper.ErrorCode
  import ShortMaps

  alias Helper.ORM
  alias MastaniServer.Accounts.User
  alias MastaniServer.Billing.BillRecord
  alias MastaniServer.Repo

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

  defp do_create_record(%User{} = user, attrs) do
    attrs = Map.merge(attrs, %{user_id: user.id, hash_id: Nanoid.generate(8), state: "pending"})
    BillRecord |> ORM.create(attrs)
  end

  def list_records(%User{id: user_id}, %{page: page, size: size} = _filter) do
    with {:ok, user} <- ORM.find(User, user_id) do
      BillRecord
      |> where([r], r.user_id == ^user.id)
      |> ORM.paginater(page: page, size: size)
      |> done()
    end
  end

  def update_record_state(record_id, state) do
    state = to_string(state)

    with {:ok, bill_record} <- ORM.find(BillRecord, record_id) do
      bill_record
      |> Ecto.Changeset.change(~m(state)a)
      |> BillRecord.state_changeset(~m(state)a)
      |> Repo.update()

      # TODO: after_action
    end
  end
end
