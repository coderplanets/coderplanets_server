defmodule GroupherServer.CMS.RepoFavorite do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts
  alias GroupherServer.CMS.Repo

  @required_fields ~w(user_id repo_id)a
  @optional_fields ~w(category_id)a

  @type t :: %RepoFavorite{}
  schema "repos_favorites" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:repo, Repo, foreign_key: :repo_id)

    belongs_to(:category, Accounts.FavoriteCategory)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%RepoFavorite{} = repo_favorite, attrs) do
    repo_favorite
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :repos_favorites_user_id_repo_id_index)
  end

  @doc false
  def update_changeset(%RepoFavorite{} = repo_favorite, attrs) do
    repo_favorite
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> unique_constraint(:user_id, name: :repos_favorites_user_id_repo_id_index)
  end
end
