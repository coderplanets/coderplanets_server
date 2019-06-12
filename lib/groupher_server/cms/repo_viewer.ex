defmodule GroupherServer.CMS.RepoViewer do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts
  alias GroupherServer.CMS.Repo

  @required_fields ~w(repo_id user_id)a

  @type t :: %RepoViewer{}
  schema "repos_viewers" do
    belongs_to(:repo, Repo, foreign_key: :repo_id)
    belongs_to(:user, Accounts.User, foreign_key: :user_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%RepoViewer{} = repo_viewer, attrs) do
    repo_viewer
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :repos_viewers_repo_id_user_id_index)
  end
end
