defmodule GroupherServer.CMS.ArticleTag do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.{Author, Community, Job, Post}

  @required_fields ~w(thread title color author_id community_id)a
  # @required_fields ~w(thread title color author_id  community_id)a

  @type t :: %ArticleTag{}
  schema "article_tags" do
    field(:title, :string)
    field(:color, :string)
    field(:thread, :string)
    belongs_to(:community, Community)
    belongs_to(:author, Author)

    # many_to_many(
    #   :posts,
    #   Post,
    #   join_through: "posts_tags",
    #   join_keys: [post_id: :id, tag_id: :id],
    #   on_delete: :delete_all
    # )

    # many_to_many(
    #   :jobs,
    #   Job,
    #   join_through: "jobs_tags",
    #   join_keys: [job_id: :id, tag_id: :id]
    # )

    timestamps(type: :utc_datetime)
  end

  def changeset(%ArticleTag{} = tag, attrs) do
    tag
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:community_id)

    # |> unique_constraint(:tag_duplicate, name: :tags_community_id_thread_title_index)

    # |> foreign_key_constraint(name: :posts_tags_tag_id_fkey)
  end
end
