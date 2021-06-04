defmodule GroupherServer.CMS.Model.CommunityCheatsheet do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS

  alias CMS.Model.{Community, GithubContributor}

  @required_fields ~w(community_id last_sync)a
  @optional_fields ~w(readme)a

  @type t :: %CommunityCheatsheet{}
  schema "community_cheatsheets" do
    belongs_to(:community, Community)

    field(:readme, :string)
    embeds_many(:contributors, GithubContributor, on_replace: :delete)
    field(:last_sync, :utc_datetime)

    field(:views, :integer, default: 0)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CommunityCheatsheet{} = community_cheatsheet, attrs) do
    community_cheatsheet
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:contributors, with: &GithubContributor.changeset/2)
    |> validate_required(@required_fields)
  end

  @doc false
  def update_changeset(%CommunityCheatsheet{} = community_cheatsheet, attrs) do
    community_cheatsheet
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:contributors, with: &GithubContributor.changeset/2)
  end
end
