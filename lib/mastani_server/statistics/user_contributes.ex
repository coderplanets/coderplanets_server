defmodule MastaniServer.Statistics.UserContributes do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_contributes" do
    field(:count, :integer)
    field(:date, :date)
    field(:user_id, :id)

    timestamps()
  end

  @doc false
  def changeset(user_contributes, attrs) do
    user_contributes
    |> cast(attrs, [:date, :count, :user_id])
    |> validate_required([:date, :count, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
