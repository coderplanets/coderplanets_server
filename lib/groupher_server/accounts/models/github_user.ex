defmodule GroupherServer.Accounts.Model.GithubUser do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts.Model.User

  @type t :: %GithubUser{}
  schema "github_users" do
    belongs_to(:user, User)

    field(:github_id, :string)
    field(:login, :string)
    field(:avatar_url, :string)
    field(:url, :string)
    field(:html_url, :string)
    field(:name, :string)
    field(:company, :string)
    field(:blog, :string)
    field(:location, :string)
    field(:email, :string)
    field(:bio, :string)
    field(:public_repos, :integer)
    field(:public_gists, :integer)
    field(:followers, :integer)
    field(:following, :integer)
    field(:access_token, :string)
    field(:node_id, :string)

    timestamps(type: :utc_datetime)
  end

  # @required_fields ~w(github_id login name avatar_url)a
  @required_fields ~w(github_id login avatar_url user_id access_token node_id)a
  @optional_fields ~w(blog company email bio followers following location html_url public_repos public_gists)a

  @doc false
  def changeset(%GithubUser{} = github_user, attrs) do
    # |> cast(attrs, [:username, :nickname, :bio, :company])
    # |> validate_required([:username])
    # |> cast(attrs, @required_fields, @optional_fields)
    github_user
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:github_id)
    |> unique_constraint(:node_id)
    |> foreign_key_constraint(:user_id)

    # |> validate_length(:username, max: 20)
    # |> unique_constraint(:username)
  end
end
