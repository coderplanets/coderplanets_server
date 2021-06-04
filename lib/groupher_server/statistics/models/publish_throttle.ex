defmodule GroupherServer.Statistics.Model.PublishThrottle do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts
  alias Accounts.Model.User

  @optional_fields ~w(user_id publish_hour publish_date hour_count date_count last_publish_time)a
  @required_fields ~w(user_id)a

  @type t :: %PublishThrottle{}
  schema "publish_throttles" do
    field(:publish_hour, :utc_datetime)
    field(:publish_date, :date)
    field(:hour_count, :integer)
    field(:date_count, :integer)
    belongs_to(:user, User)

    field(:last_publish_time, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PublishThrottle{} = publish_throttle, attrs) do
    publish_throttle
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user, name: :publish_throttles_user_id_index)
  end

  @doc false
  def update_changeset(%PublishThrottle{} = publish_throttle, attrs) do
    publish_throttle
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user, name: :publish_throttles_user_id_index)
  end
end
