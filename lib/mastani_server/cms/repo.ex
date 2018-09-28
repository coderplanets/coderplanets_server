defmodule MastaniServer.CMS.Repo do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Author, Community, RepoContributor, RepoCommunityFlag, Tag}

  @required_fields ~w(title owner_name owner_url repo_url desc homepage_url readme issues_count prs_count fork_count watch_count primary_language license release_tag)a
  @optional_fields ~w(last_fetch_time)

  @type t :: %Repo{}
  schema "cms_repos" do
    field(:title, :string)
    field(:owner_name, :string)
    field(:owner_url, :string)
    field(:repo_url, :string)

    field(:desc, :string)
    field(:homepage_url, :string)
    field(:readme, :string)

    field(:issues_count, :integer)
    field(:prs_count, :integer)
    field(:fork_count, :integer)
    field(:watch_count, :integer)

    field(:primary_language, :string)
    field(:license, :string)
    field(:release_tag, :string)

    embeds_many(:contributors, RepoContributor)

    field(:views, :integer, default: 0)
    belongs_to(:author, Author)
    has_many(:community_flags, {"repos_communities_flags", RepoCommunityFlag})

    # NOTE: this one is tricky, pin is dynamic changed when return by func: add_pin_contents_ifneed
    field(:pin, :boolean, default_value: false)
    field(:trash, :boolean, default_value: false)

    field(:last_fetch_time, :utc_datetime)

    many_to_many(
      :tags,
      Tag,
      join_through: "repos_tags",
      join_keys: [repo_id: :id, tag_id: :id],
      on_delete: :delete_all,
      on_replace: :delete
    )

    many_to_many(
      :communities,
      Community,
      join_through: "communities_repos",
      on_replace: :delete
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Repo{} = repo, attrs) do
    repo
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)

    # |> foreign_key_constraint(:posts_tags, name: :posts_tags_tag_id_fkey)
    # |> foreign_key_constraint(name: :posts_tags_tag_id_fkey)
  end
end
