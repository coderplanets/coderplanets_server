defmodule MastaniServer.Accounts.Bill do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts.User

  @required_fields ~w(from_user_id to_user_id source_type source_title price)a
  @optional_fields ~w(source_id)a

  @type t :: %Bill{}
  schema "bills" do
    belongs_to(:from_user, User)
    belongs_to(:to_user, User)

    field(:source_id, :string)
    field(:source_title, :string)
    field(:source_type, :string)
    field(:price, :integer)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Bill{} = bill, attrs) do
    bill
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:from_user_id)
    |> foreign_key_constraint(:to_user_id)
  end
end
