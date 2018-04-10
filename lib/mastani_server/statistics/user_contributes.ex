defmodule MastaniServer.Statistics.UserContributes do
  use Ecto.Schema
  import Ecto.Changeset

  alias MastaniServer.Accounts
  alias MastaniServer.Statistics.UserContributes

  schema "user_contributes" do
    field(:count, :integer)
    field(:date, :date)
    belongs_to(:user, Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(%UserContributes{} = user_contributes, attrs) do
    user_contributes
    |> cast(attrs, [:date, :count, :user_id])
    |> validate_required([:date, :count, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
