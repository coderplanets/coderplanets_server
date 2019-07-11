defmodule GroupherServer.CMS.Community do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias CMS.{
    Category,
    Post,
    Video,
    Repo,
    Job,
    CommunityThread,
    CommunitySubscriber,
    CommunityEditor,
    CommunityWiki,
    CommunityCheatsheet
  }

  @required_fields ~w(title desc user_id logo raw)a
  # @required_fields ~w(title desc user_id)a
  @optional_fields ~w(label geo_info index aka)a

  schema "communities" do
    field(:title, :string)
    field(:aka, :string)
    field(:desc, :string)
    field(:logo, :string)
    # field(:category, :string)
    field(:label, :string)
    field(:raw, :string)
    field(:index, :integer)
    field(:geo_info, :map)

    belongs_to(:author, Accounts.User, foreign_key: :user_id)

    has_many(:threads, {"communities_threads", CommunityThread})
    has_many(:subscribers, {"communities_subscribers", CommunitySubscriber})
    has_many(:editors, {"communities_editors", CommunityEditor})

    has_one(:wiki, CommunityWiki)
    has_one(:cheatsheet, CommunityCheatsheet)

    many_to_many(
      :categories,
      Category,
      join_through: "communities_categories",
      join_keys: [community_id: :id, category_id: :id],
      # :delete_all will only remove data from the join source
      on_delete: :delete_all
      # on_replace: :delete
    )

    many_to_many(
      :posts,
      Post,
      join_through: "communities_posts",
      join_keys: [community_id: :id, post_id: :id]
    )

    many_to_many(
      :videos,
      Video,
      join_through: "communities_videos",
      join_keys: [community_id: :id, video_id: :id]
    )

    many_to_many(
      :repos,
      Repo,
      join_through: "communities_repos",
      join_keys: [community_id: :id, repo_id: :id]
    )

    many_to_many(
      :jobs,
      Job,
      join_through: "communities_jobs",
      join_keys: [community_id: :id, job_id: :id]
    )

    # posts_managers
    # jobs_managers
    # tuts_managers
    # videos_managers
    #
    # posts_block_list ...
    # videos_block_list ...
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Community{} = community, attrs) do
    # |> cast_assoc(:author)
    # |> unique_constraint(:title, name: :communities_title_index)
    community
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 1, max: 30)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:title, name: :communities_title_index)
    |> unique_constraint(:aka, name: :communities_aka_index)

    # |> foreign_key_constraint(:communities_author_fkey)
    # |> unique_constraint(:user_id, name: :posts_favorites_user_id_post_id_index)
  end

  @doc false
  def update_changeset(%Community{} = community, attrs) do
    # |> cast_assoc(:author)
    # |> unique_constraint(:title, name: :communities_title_index)
    community
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_length(:title, min: 1, max: 30)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:title, name: :communities_title_index)
    |> unique_constraint(:aka, name: :communities_aka_index)

    # |> foreign_key_constraint(:communities_author_fkey)
    # |> unique_constraint(:user_id, name: :posts_favorites_user_id_post_id_index)
  end
end
