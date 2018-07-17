defmodule MastaniServer.CMS.Repo do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Author, Community, RepoBuilder, Tag}

  @required_fields ~w(repo_name desc readme language producer producer_link repo_link repo_star_count repo_fork_count repo_watch_count)a
  @optional_fields ~w(views pin trash last_fetch_time)

  @type t :: %Repo{}
  schema "cms_repos" do
    field(:repo_name, :string)
    field(:desc, :string)
    field(:readme, :string)
    field(:language, :string)
    belongs_to(:author, Author)

    field(:repo_link, :string)
    field(:producer, :string)
    field(:producer_link, :string)

    field(:repo_star_count, :integer)
    field(:repo_fork_count, :integer)
    field(:repo_watch_count, :integer)

    field(:views, :integer, default: 0)
    field(:pin, :boolean, default_value: false)
    field(:trash, :boolean, default_value: false)

    field(:last_fetch_time, :utc_datetime)
    # TODO: replace RepoBuilder with paged user map
    has_many(:builders, {"repos_builders", RepoBuilder})

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
