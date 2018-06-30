defmodule MastaniServer.Statistics.UserContribute do
  use Ecto.Schema
  import Ecto.Changeset

  alias MastaniServer.Accounts
  alias MastaniServer.Statistics.UserContribute

  schema "user_contributes" do
    field(:count, :integer)
    field(:date, :date)
    belongs_to(:user, Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(%UserContribute{} = user_contribute, attrs) do
    user_contribute
    |> cast(attrs, [:date, :count, :user_id])
    |> validate_required([:date, :count, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
