defmodule GroupherServer.CMS.Model.Repo do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.CMS
  alias CMS.Model.{Embeds, RepoContributor, RepoLang}

  alias Helper.HTML

  @timestamps_opts [type: :utc_datetime_usec]
  @required_fields ~w(title owner_name owner_url repo_url desc readme star_count issues_count prs_count fork_count watch_count)a
  @article_cast_fields general_article_cast_fields()
  @optional_fields @article_cast_fields ++ ~w(last_sync homepage_url release_tag license)a

  @type t :: %Repo{}
  schema "cms_repos" do
    field(:owner_name, :string)
    field(:owner_url, :string)
    field(:repo_url, :string)

    field(:desc, :string)
    field(:homepage_url, :string)
    field(:readme, :string)

    field(:star_count, :integer)
    field(:issues_count, :integer)
    field(:prs_count, :integer)
    field(:fork_count, :integer)
    field(:watch_count, :integer)

    field(:license, :string)
    field(:release_tag, :string)
    embeds_one(:primary_language, RepoLang, on_replace: :delete)
    embeds_many(:contributors, RepoContributor, on_replace: :delete)
    field(:last_sync, :utc_datetime)

    article_tags_field(:repo)
    article_communities_field(:repo)
    general_article_fields(:repo)
  end

  @doc false
  def changeset(%Repo{} = repo, attrs) do
    repo
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%Repo{} = repo, attrs) do
    repo
    |> cast(attrs, @optional_fields ++ @required_fields)
    # |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  defp generl_changeset(content) do
    content
    |> validate_length(:title, min: 1, max: 80)
    |> cast_embed(:contributors, with: &RepoContributor.changeset/2)
    |> cast_embed(:primary_language, with: &RepoLang.changeset/2)
    |> HTML.safe_string(:readme)
  end
end
