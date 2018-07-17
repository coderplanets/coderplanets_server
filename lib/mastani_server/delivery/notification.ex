defmodule MastaniServer.Delivery.Notification do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias MastaniServer.Accounts.User

  @required_fields ~w(from_user_id to_user_id action source_title source_id source_preview source_type)a
  @optional_fields ~w(parent_id parent_type read)a

  @type t :: %Notification{}
  schema "notifications" do
    belongs_to(:from_user, User)
    belongs_to(:to_user, User)
    field(:action, :string)

    field(:source_id, :string)
    field(:source_preview, :string)
    field(:source_title, :string)
    field(:source_type, :string)
    field(:parent_id, :string)
    field(:parent_type, :string)
    field(:read, :boolean)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Notification{} = notification, attrs) do
    notification
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:from_user_id)
    |> foreign_key_constraint(:to_user_id)
  end
end
