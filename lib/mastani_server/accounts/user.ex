defmodule MastaniServer.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts.{User, GithubUser}

  schema "users" do
    field(:nickname, :string)
    field(:avatar, :string)
    field(:sex, :string)
    field(:bio, :string)
    field(:from_github, :boolean)
    has_one(:github_profile, GithubUser)

    # has_many(::following_communities, {"communities_subscribers", CommunitySubscriber})
    # has_many(:follow_communities, {"communities_subscribers", CommunitySubscriber})

    # has_one(:hobbies, Hobbies)

    timestamps(type: :utc_datetime)
  end

  @optional_fields ~w(nickname bio avatar sex)a
  @required_fields ~w(nickname avatar)a

  @doc false
  def changeset(%User{} = user, attrs) do
    # |> cast(attrs, [:username, :nickname, :bio, :company])
    # |> validate_required([:username])
    # |> cast(attrs, @required_fields, @optional_fields)
    user
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:nickname, max: 30)

    # |> unique_constraint(:username)
  end
end
