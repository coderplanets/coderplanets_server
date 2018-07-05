defmodule MastaniServer.Accounts.Customization do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts.{User, Customization}

  @required_fields ~w(user_id)a
  @optional_fields ~w(theme community_chart brainwash_free)a

  schema "customizations" do
    belongs_to(:user, User)

    field(:theme, :boolean)
    field(:community_chart, :boolean)
    field(:brainwash_free, :boolean)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Customization{} = customization, attrs) do
    customization
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
  end
end
