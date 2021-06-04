defmodule GroupherServer.Delivery.Record do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts.Model.User

  @required_fields ~w(user_id)a
  @optional_fields ~w(mentions_record notifications_record sys_notifications_record)a

  @type t :: %Record{}
  schema "delivery_records" do
    field(:mentions_record, :map)
    field(:notifications_record, :map)
    field(:sys_notifications_record, :map)
    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Record{} = record, attrs) do
    record
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
  end
end
