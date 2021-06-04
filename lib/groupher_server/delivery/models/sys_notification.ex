defmodule GroupherServer.Delivery.Model.SysNotification do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(source_title source_id source_type)a
  @optional_fields ~w(source_preview)a

  @type t :: %SysNotification{}
  schema "sys_notifications" do
    field(:source_id, :string)
    field(:source_title, :string)
    field(:source_type, :string)
    field(:source_preview, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%SysNotification{} = sys_notification, attrs) do
    sys_notification
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:from_user_id)
    |> foreign_key_constraint(:to_user_id)
  end
end
