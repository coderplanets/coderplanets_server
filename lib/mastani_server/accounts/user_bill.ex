defmodule MastaniServer.Accounts.UserBill do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts.{User, Bill, UserBill}

  @required_fields ~w(user_id bill_id)a

  schema "users_bills" do
    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:bill, Bill, foreign_key: :bill_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%UserBill{} = user_bill, attrs) do
    user_bill
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:bill_id)
  end
end
