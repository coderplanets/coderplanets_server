defmodule MastaniServer.CMS.PinedRepo do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Community, Repo}

  @required_fields ~w(repo_id community_id)a

  @type t :: %PinedRepo{}
  schema "pined_repos" do
    belongs_to(:repo, Repo, foreign_key: :repo_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PinedRepo{} = pined_repo, attrs) do
    pined_repo
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:repo_id)
    |> foreign_key_constraint(:community_id)
    |> unique_constraint(:pined_repos, name: :pined_repos_repo_id_community_id_index)
  end
end
