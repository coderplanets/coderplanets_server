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

  @required_fields ~w(username)a
  @optional_fields ~w(nickname bio company)a

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, @required_fields, @optional_fields)
    # |> cast(attrs, [:username, :nickname, :bio, :company])
    # |> validate_required([:username])
    |> validate_required(@required_fields)
    |> validate_length(:username, max: 5)
    |> unique_constraint(:username)
  end
end
