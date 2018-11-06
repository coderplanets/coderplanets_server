defmodule MastaniServer.CMS.Topic do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  # alias MastaniServer.CMS.{Author, Community, Job, Post, Video}

  @required_fields ~w(thread title raw)a

  @type t :: %Topic{}
  schema "topics" do
    field(:title, :string)
    field(:thread, :string)
    field(:raw, :string)

    # many_to_many(
    # :posts,
    # Post,
    # join_through: "posts_tags",
    # join_keys: [post_id: :id, tag_id: :id],
    # on_delete: :delete_all
    # )

    # many_to_many(
    # :videos,
    # Video,
    # join_through: "videos_tags",
    # join_keys: [video_id: :id, tag_id: :id]
    # )

    # many_to_many(
    # :jobs,
    # Job,
    # join_through: "jobs_tags",
    # join_keys: [job_id: :id, tag_id: :id]
    # )

    timestamps(type: :utc_datetime)
  end

  def changeset(%Topic{} = topic, attrs) do
    topic
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)

    # |> unique_constraint(:tag_duplicate, name: :tags_community_id_thread_title_index)
  end
end
