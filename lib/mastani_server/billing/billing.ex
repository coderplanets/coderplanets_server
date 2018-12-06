defmodule MastaniServer.Billing do
  @moduledoc """
  CURD for all the finacial records
  """
  import Ecto.Query, warn: false
  import Helper.Utils
  import Helper.ErrorCode

  alias Helper.ORM
  alias MastaniServer.Accounts.User
  alias MastaniServer.Billing.BillRecord

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

  def get_records(%User{id: user_id}, %{page: page, size: size} = _filter) do
    with {:ok, user} <- ORM.find(User, user_id) do
      BillRecord
      |> where([r], r.user_id == ^user.id)
      |> ORM.paginater(page: page, size: size)
      |> done()
    end
  end
end
