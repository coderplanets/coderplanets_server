defmodule GroupherServer.CMS.RepoCommunityFlag do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.{Community, Repo}

  @required_fields ~w(repo_id community_id)a
  @optional_fields ~w(trash)a

  @type t :: %RepoCommunityFlag{}

  schema "repos_communities_flags" do
    belongs_to(:repo, Repo, foreign_key: :repo_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    field(:trash, :boolean)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%RepoCommunityFlag{} = repo_community_flag, attrs) do
    repo_community_flag
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:repo_id)
    |> foreign_key_constraint(:community_id)
    |> unique_constraint(:repo_id, name: :repos_communities_flags_repo_id_community_id_index)
  end
end
