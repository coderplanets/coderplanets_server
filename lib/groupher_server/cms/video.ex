defmodule GroupherServer.CMS.Video do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS.{
    Author,
    Community,
    VideoComment,
    VideoFavorite,
    VideoCommunityFlag,
    VideoStar,
    VideoViewer,
    Tag
  }

  @timestamps_opts [type: :utc_datetime_usec]
  @required_fields ~w(title poster thumbnil desc duration duration_sec source link original_author original_author_link publish_at)a
  @optional_fields ~w(origial_community_id  title poster thumbnil desc duration duration_sec source link original_author original_author_link publish_at)a

  @type t :: %Video{}
  schema "cms_videos" do
    field(:title, :string)
    field(:poster, :string)
    field(:thumbnil, :string)
    field(:desc, :string)
    field(:duration, :string)
    field(:duration_sec, :integer)
    belongs_to(:author, Author)
    field(:source, :string)
    field(:link, :string)

    field(:original_author, :string)
    field(:original_author_link, :string)

    field(:views, :integer, default: 0)
    field(:publish_at, :utc_datetime)

    has_many(:community_flags, {"videos_communities_flags", VideoCommunityFlag})

    # NOTE: this one is tricky, pin is dynamic changed when return by func: add_pin_contents_ifneed
    field(:pin, :boolean, default_value: false)
    field(:trash, :boolean, default_value: false)

    has_many(:favorites, {"videos_favorites", VideoFavorite})
    has_many(:stars, {"videos_stars", VideoStar})
    has_many(:viewers, {"videos_viewers", VideoViewer})
    has_many(:comments, {"videos_comments", VideoComment})

    many_to_many(
      :tags,
      Tag,
      join_through: "videos_tags",
      join_keys: [video_id: :id, tag_id: :id],
      on_delete: :delete_all,
      on_replace: :delete
    )

    belongs_to(:origial_community, Community)

    many_to_many(
      :communities,
      Community,
      join_through: "communities_videos",
      on_replace: :delete
    )

    # timestamps(type: :utc_datetime)
    timestamps()
  end

  @doc false
  def changeset(%Video{} = video, attrs) do
    video
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> generl_changeset
  end

  def update_changeset(%Video{} = video, attrs) do
    video
    |> cast(attrs, @optional_fields)
    |> generl_changeset
  end

  defp generl_changeset(content) do
    content
    |> validate_length(:title, min: 3, max: 50)
    |> validate_length(:desc, min: 3, max: 200)
    |> validate_length(:original_author, min: 3, max: 30)
    |> validate_length(:original_author_link, min: 5, max: 200)
    |> validate_length(:link, min: 5, max: 200)
  end

  def update_changeset(%Video{} = video, attrs) do
    video
    |> cast(attrs, @optional_fields)
    |> validate_length(:original_author, min: 3, max: 30)
  end
end
