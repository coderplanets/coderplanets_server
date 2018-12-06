defmodule MastaniServer.Billing.BillRecord do
  @moduledoc """
  bill records for investors
  """
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias MastaniServer.Accounts

  @required_fields ~w(user_id hash_id state amount payment_usage payment_method)a
  @optional_fields ~w(note)a

  schema "bill_records" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)

    field(:state, :string)
    field(:amount, :float)

    field(:hash_id, :string)
    field(:payment_usage, :string)
    field(:payment_method, :string)

    field(:note, :string)

    timestamps(type: :utc_datetime)
  end

  def changeset(%BillRecord{} = bill_record, attrs) do
    bill_record
    # |> cast(attrs, @optional_fields ++ @required_fields)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    # |> validate_length(:title, min: 1, max: 30)
    |> foreign_key_constraint(:user_id)
  end
end
