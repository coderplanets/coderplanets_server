defmodule MastaniServer.Statistics.PublishThrottle do
  use Ecto.Schema
  import Ecto.Changeset

  alias MastaniServer.Accounts
  alias MastaniServer.Statistics.PublishThrottle

  @optional_fields ~w(user_id publish_hour publish_date hour_count date_count last_publish_time)a
  # @required_fields ~w(title desc user_id)a
  @required_fields ~w(user_id)a

  schema "publish_throttles" do
    field(:publish_hour, :utc_datetime)
    field(:publish_date, :date)
    field(:hour_count, :integer)
    field(:date_count, :integer)
    belongs_to(:user, Accounts.User)

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
end
