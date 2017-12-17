defmodule MastaniServer.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts.User

  schema "users" do
    field(:username, :string)
    field(:nickname, :string)
    field(:bio, :string)
    field(:company, :string)

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :nickname, :bio, :company])
    |> validate_required([:username])
    |> unique_constraint(:username)
  end
end
