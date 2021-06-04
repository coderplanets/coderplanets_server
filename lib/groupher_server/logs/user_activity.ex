defmodule GroupherServer.Logs.UserActivity do
  @moduledoc false
  # alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.Accounts.Model.User

  @required_fields ~w(user_id source_title source_id source_type)a
  # @optional_fields ~w(source_type)a

  schema "user_activity_logs" do
    belongs_to(:user, User)

    field(:source_id, :string)
    field(:source_title, :string)
    field(:source_type, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_activity, attrs) do
    user_activity
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
