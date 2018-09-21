defmodule MastaniServer.CMS.Video do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Author, Community, VideoCommunityFlag, Tag}

  @required_fields ~w(title poster thumbnil desc duration duration_sec source link original_author original_author_link publish_at)a
  # @optional_fields ~w()a

  @type t :: %Video{}
  schema "cms_videos" do
    field(:title, :string)
    field(:poster, :string)
    field(:thumbnil, :string)
    field(:desc, :string)
    field(:duration, :string)
    field(:duration_sec, :integer)

    field(:source, :string)
    field(:link, :string)

    field(:original_author, :string)
    field(:original_author_link, :string)

    field(:views, :integer, default: 0)

    has_many(:community_flags, {"videos_communities_flags", VideoCommunityFlag})

    # NOTE: this one is tricky, pin is dynamic changed when return by func: add_pin_contents_ifneed
    field(:pin, :boolean, default_value: false)
    field(:trash, :boolean, default_value: false)

    field(:publish_at, :utc_datetime)

    belongs_to(:author, Author)

    # has_many(:comments, {"posts_comments", PostComment})

    many_to_many(
      :tags,
      Tag,
      join_through: "videos_tags",
      join_keys: [video_id: :id, tag_id: :id],
      on_delete: :delete_all,
      on_replace: :delete
    )

    many_to_many(
      :communities,
      Community,
      join_through: "communities_videos",
      on_replace: :delete
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Video{} = video, attrs) do
    video
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)

    # |> foreign_key_constraint(:posts_tags, name: :posts_tags_tag_id_fkey)
    # |> foreign_key_constraint(name: :posts_tags_tag_id_fkey)
  end
end
